#!/usr/bin/env python3
"""Où en sont les passes longues, en une page.

Deux travaux tournent en parallèle et ne se ressemblent pas : la distillation
tient le GPU et se juge à la largeur de son cône, l'extraction de
Pl@ntNet-300K tient le réseau et se juge à ce qui reste à tirer. Les suivre
demandait trois `tail` et un `ls` dans deux terminaux.

**Ce script ne lit que des fichiers déjà écrits.** Ni GPU, ni réseau, ni
modèle chargé : il peut tourner en boucle sans rien coûter aux deux passes.

    python3 suivi.py
    python3 suivi.py --boucle 30

Le chiffre qui décide n'est pas ici. Il est dans `voisins.py --embeddings`,
sur un `banc-eN` que ce tableau se contente de signaler dès qu'il existe
(§ 19 bis de `docs/14` : on s'arrête sur le top-1 par référence, jamais sur
la perte).
"""
import argparse
import csv
import json
import re
import shutil
import subprocess
import time
from pathlib import Path

# `  é0 pas 6800/12468  perte 0.4078  accord 0.6941  cône 0.3015  267 img/s`
ENTRAINEMENT = re.compile(
    r'é(\d+) pas (\d+)/(\d+)\s+perte ([\d.]+)\s+accord ([\d.]+)\s+'
    r'c[ôo]ne ([\d.]+)\s+(\d+) img/s')
# `  12000/243567  31.4 img/s  3 sautées  reste 123 min`
CORPUS = re.compile(r'(\d+)/(\d+)\s+([\d.]+) img/s\s+(\d+) saut')
# `  12800/243567  79.9 img/s  reste 0.8 h` — la passe du teacher. Elle ne
# porte pas de « sautées » : le cache n'a pas le droit d'en perdre.
CACHE = re.compile(r'(\d+)/(\d+)\s+([\d.]+) img/s\s+reste ([\d.]+) h')

CONE_TEACHER = 0.2806  # § 19 ter de docs/14 — la géométrie qu'on copie
# Ce qu'annonce Zenodo pour `plantnet_300K.zip`, au centième de Gio près. Le
# pourcentage est donc approché, et c'est assez : ce qu'on veut savoir est si
# ça avance, pas à quel octet on en est.
ARCHIVE_GIO = 29.49


# --------------------------------------------------------------------------
# Lire les journaux
# --------------------------------------------------------------------------

def derniere(lignes: list[str], motif: re.Pattern) -> re.Match | None:
    """La dernière ligne qui correspond, en remontant.

    Remonter plutôt que tout parcourir : un journal de nuit fait des dizaines
    de milliers de lignes et seule la dernière dit où on en est.
    """
    for ligne in reversed(lignes):
        m = motif.search(ligne)
        if m:
            return m
    return None


def etat_entrainement(lignes: list[str]) -> dict | None:
    m = derniere(lignes, ENTRAINEMENT)
    if not m:
        return None
    epoque, pas, total = int(m[1]), int(m[2]), int(m[3])
    return {'epoque': epoque, 'pas': pas, 'pas_total': total,
            'perte': float(m[4]), 'accord': float(m[5]), 'cone': float(m[6]),
            'vitesse': int(m[7]), 'part': pas / total if total else 0.0}


def etat_corpus(lignes: list[str]) -> dict | None:
    m = derniere(lignes, CORPUS)
    if not m:
        return None
    faites, total = int(m[1]), int(m[2])
    return {'faites': faites, 'total': total, 'vitesse': float(m[3]),
            'sautees': int(m[4]), 'part': faites / total if total else 0.0}


def etat_cache(lignes: list[str]) -> dict | None:
    """L'avancée de `bioclip.py cache`, et si elle est finie.

    La fin ne se lit pas sur le compteur : la dernière ligne de progression
    s'écrit avant le dernier fragment. C'est la ligne de signature, écrite
    après la boucle, qui dit que le cache est complet et lisible.
    """
    finie = any('— signature' in l for l in lignes)
    m = derniere(lignes, CACHE)
    if not m and not finie:
        return None
    fait, total = (int(m[1]), int(m[2])) if m else (0, 0)
    return {'fait': fait, 'total': total, 'finie': finie,
            'vitesse': float(m[3]) if m else 0.0,
            'part': 1.0 if finie else (fait / total if total else 0.0)}


def reste(fait: int, total: int, vitesse: float, par_pas: int = 1) -> float:
    """Les secondes restantes, 0 si on ne peut pas savoir.

    Une vitesse nulle rendrait l'infini, qui s'affiche mal et n'apprend rien.
    """
    if vitesse <= 0 or total <= fait:
        return 0.0
    return (total - fait) * par_pas / vitesse


def duree(secondes: float) -> str:
    """`4 h 12`, `37 min`, `—`. Jamais `4.2 heures`, qu'on relit deux fois."""
    if secondes <= 0:
        return '—'
    if secondes < 3600:
        return f'{secondes / 60:.0f} min'
    return f'{int(secondes // 3600)} h {int(secondes % 3600 // 60):02d}'


def barre(part: float, largeur: int = 28) -> str:
    plein = max(0, min(largeur, round(part * largeur)))
    return '█' * plein + '·' * (largeur - plein)


def avancement(octets: int, attendus: float, avant: tuple[int, float] | None,
               maintenant: float) -> dict:
    """Où en est un fichier qui grossit, et à quelle vitesse.

    La vitesse se mesure entre deux rafraîchissements plutôt que depuis le
    début : un téléchargement repris après coupure a passé des minutes à zéro,
    et une moyenne depuis le lancement annoncerait des heures de trop.
    """
    part = octets / (attendus * 1024 ** 3) if attendus else 0.0
    etat = {'octets': octets, 'part': part, 'vitesse': 0.0, 'reste': 0.0}
    if avant is None:
        return etat
    gagnes, ecoule = octets - avant[0], maintenant - avant[1]
    if ecoule <= 0 or gagnes <= 0:
        return etat
    etat['vitesse'] = gagnes / ecoule
    etat['reste'] = max(0.0, attendus * 1024 ** 3 - octets) / etat['vitesse']
    return etat


# --------------------------------------------------------------------------
# La tendance du cône
# --------------------------------------------------------------------------

def tendance(journal: list[dict], combien: int = 400) -> dict | None:
    """Le cône au début de la fenêtre et à sa fin.

    **Le signal d'alarme du § 19 bis**, et il ne se lit pas sur un point : un
    cône qui se referme pendant que la perte descend annonce un student qui ne
    saura rien retrouver. Deux points disent le sens, une valeur seule non.
    """
    valeurs = [float(r['cone']) for r in journal if r.get('cone')]
    if len(valeurs) < 2:
        return None
    fenetre = valeurs[-combien:]
    return {'debut': fenetre[0], 'fin': fenetre[-1],
            'ecart': fenetre[-1] - fenetre[0], 'points': len(fenetre)}


def lire_journal(chemin: Path) -> list[dict]:
    if not chemin.exists():
        return []
    with open(chemin, newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def epoques_ecrites(sortie: Path) -> list[int]:
    """Les `banc-eN` qui existent — les seuls points mesurables."""
    return sorted(int(d.name.split('banc-e')[1]) for d in sortie.glob('banc-e*')
                  if d.is_dir() and d.name.split('banc-e')[1].isdigit())


# --------------------------------------------------------------------------
# L'affichage
# --------------------------------------------------------------------------

def lignes(chemin: Path, combien: int = 4000) -> list[str]:
    """Les dernières lignes d'un journal, sans le relire en entier."""
    if not chemin.exists():
        return []
    with open(chemin, encoding='utf-8', errors='replace') as f:
        return f.readlines()[-combien:]


def silence(chemin: Path, maintenant: float | None = None) -> str:
    """Pourquoi un journal ne dit rien : absent, ou muet depuis quand.

    « Aucune ligne de progression » confond deux situations opposées — une
    passe qui n'a pas été lancée et une passe bloquée. La seconde demande une
    intervention, la première un `tmux`.
    """
    if not chemin.exists():
        return f'{chemin} absent — la passe n\'a pas été lancée'
    ecoule = (maintenant or time.time()) - chemin.stat().st_mtime
    return f'journal muet depuis {duree(ecoule)}' if ecoule > 90 else \
        'démarrage, première ligne dans quelques secondes'


def gpu() -> str:  # pragma: no cover - demande nvidia-smi
    if not shutil.which('nvidia-smi'):
        return ''
    try:
        s = subprocess.run(
            ['nvidia-smi', '--query-gpu=utilization.gpu,memory.used,memory.total',
             '--format=csv,noheader,nounits'],
            capture_output=True, text=True, timeout=5).stdout.strip()
        u, utilisee, totale = (x.strip() for x in s.split(','))
        return f'{u} %, {int(utilisee) / 1024:.1f}/{int(totale) / 1024:.1f} Gio'
    except Exception:
        return ''


_precedent: dict[str, tuple[int, float]] = {}


def tableau(args) -> str:  # pragma: no cover - assemble des lectures disque
    sortie = Path(args.sortie).expanduser()
    out = [f"── {time.strftime('%H:%M:%S')} ─────────────────────────────────"]

    e = etat_entrainement(lignes(Path(args.log).expanduser()))
    out.append('\nDISTILLATION')
    if e is None:
        out.append(f'  {silence(Path(args.log).expanduser())}')
    else:
        epoques = args.epoques
        fait = e['epoque'] * e['pas_total'] + e['pas']
        out.append(f"  époque {e['epoque'] + 1}/{epoques}   {barre(e['part'])} "
                   f"{e['part'] * 100:4.1f} %   {e['vitesse']} img/s")
        out.append(f"  perte {e['perte']:.4f}   accord {e['accord']:.4f}   "
                   f"cône {e['cone']:.4f}  (teacher {CONE_TEACHER})")
        out.append(f"  reste époque {duree(reste(e['pas'], e['pas_total'], e['vitesse'], args.batch))}"
                   f"   passe {duree(reste(fait, epoques * e['pas_total'], e['vitesse'], args.batch))}")
    t = tendance(lire_journal(sortie / 'journal.csv'))
    if t:
        sens = 'se referme' if t['ecart'] > 0.005 else (
            "s'étale" if t['ecart'] < -0.005 else 'stable')
        out.append(f"  cône sur {t['points']} relevés : {t['debut']:.4f} → "
                   f"{t['fin']:.4f}  ({sens})")
    faites = epoques_ecrites(sortie)
    out.append(f"  points de contrôle : {', '.join(f'e{n}' for n in faites) or 'aucun'}")
    if faites:
        out.append(f"  → python3 voisins.py --banc benchmark.csv --cache {args.cache} "
                   f"--embeddings {args.sortie}/banc-e{faites[-1]}")

    archive = Path(args.archive).expanduser()
    if archive.exists() and not (sortie.parent / 'plantnet-300k' / 'splits.csv').exists():
        a = avancement(archive.stat().st_size, ARCHIVE_GIO,
                       _precedent.get('archive'), time.time())
        _precedent['archive'] = (a['octets'], time.time())
        out.append('\nARCHIVE PL@NTNET (téléchargement)')
        out.append(f"  {barre(a['part'])} {a['part'] * 100:4.1f} %   "
                   f"{a['octets'] / 1024 ** 3:.2f}/{ARCHIVE_GIO} Gio")
        if a['part'] >= 0.999:
            # Un fichier complet ne grossit plus : annoncer « vitesse
            # inconnue » là où il n'y a plus rien à attendre ferait croire à
            # un téléchargement bloqué.
            out.append('  complète — lancer `plantnet_corpus.py --archive`')
        elif a['vitesse']:
            out.append(f"  {a['vitesse'] / 1024 ** 2:.1f} Mo/s   "
                       f"reste {duree(a['reste'])}")
        else:
            out.append('  vitesse inconnue — deuxième relevé au prochain '
                       'rafraîchissement')

    k = etat_cache(lignes(Path(args.log_cache).expanduser()))
    if k:
        out.append('\nCACHE TEACHER')
        if k['finie']:
            out.append(f"  {barre(1.0)} terminé — {k['total']} vecteurs ajoutés")
        else:
            out.append(f"  {barre(k['part'])} {k['part'] * 100:4.1f} %   "
                       f"{k['fait']}/{k['total']}   {k['vitesse']:.1f} img/s")
            out.append(f"  reste {duree(reste(k['fait'], k['total'], k['vitesse']))}")

    c = etat_corpus(lignes(Path(args.log_corpus).expanduser()))
    out.append('\nCORPUS PL@NTNET')
    if c is None:
        out.append(f'  {silence(Path(args.log_corpus).expanduser())}')
    else:
        out.append(f"  {barre(c['part'])} {c['part'] * 100:4.1f} %   "
                   f"{c['faites']}/{c['total']}   {c['vitesse']:.1f} img/s")
        out.append(f"  {c['sautees']} sautées   reste "
                   f"{duree(reste(c['faites'], c['total'], c['vitesse']))}")

    carte = gpu()
    if carte:
        out.append(f'\nGPU  {carte}')
    return '\n'.join(out)


def main() -> int:  # pragma: no cover - boucle d'affichage
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--sortie', default='~/plant-data/iris10-complet')
    ap.add_argument('--log', default='~/plant-data/iris10-complet.log')
    ap.add_argument('--log-corpus', default='~/plant-data/plantnet-corpus.log')
    ap.add_argument('--log-cache', default='~/plant-data/bioclip-plantnet.log',
                    help="la passe du teacher sur un nouveau corpus")
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--archive', default='~/plant-data/plantnet_300K.zip',
                    help="le zip en cours de téléchargement")
    ap.add_argument('--epoques', type=int, default=10)
    ap.add_argument('--batch', type=int, default=64,
                    help="images par pas, pour convertir une vitesse en durée")
    ap.add_argument('--boucle', type=int, default=0, metavar='SECONDES',
                    help='rafraîchir indéfiniment au lieu d\'afficher une fois')
    args = ap.parse_args()

    etat = Path(args.sortie).expanduser() / 'etat.json'
    if etat.exists():
        try:
            e = json.loads(etat.read_text())
            print(f"student {e.get('student')}, contrastive {e.get('contrastive')}, "
                  f"{e.get('epoque')} époque(s) bouclée(s)\n")
        except Exception:
            pass

    if not args.boucle:
        print(tableau(args))
        return 0
    try:
        while True:
            print('\033[2J\033[H' + tableau(args), flush=True)
            time.sleep(args.boucle)
    except KeyboardInterrupt:
        return 0


if __name__ == '__main__':
    raise SystemExit(main())
