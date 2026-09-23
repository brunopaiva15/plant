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
import shlex
import shutil
import subprocess
import sys
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

# `  fragment 3/595  data/train-0002-of-unknown.parquet  gardées 1180/2500  —
#    cumul : 3570 gardées, 3810 hors plantes, 12 déjà au corpus, 1 écartées pour
#    le banc  reste 412 min`
INAT = re.compile(r'fragment (\d+)/(\d+)\s+(\S+)\s+gardées (\d+)/(\d+)\s+— cumul : '
                  r'(\d+) gardées, (\d+) hors plantes, (\d+) déjà au corpus, '
                  r'(\d+) écartées pour le banc\s+reste (\d+) min')

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
    """L'avancée de `plantnet_corpus.py`, et si elle est finie.

    Comme pour le cache, la fin ne se lit pas sur le compteur — il s'arrête
    au dernier multiple de 500, à 99,9 % pour toujours. C'est le bilan écrit
    après la boucle qui la dit.
    """
    finie = any('sautées cette passe' in l for l in lignes)
    m = derniere(lignes, CORPUS)
    if not m:
        return None
    faites, total = int(m[1]), int(m[2])
    return {'faites': faites, 'total': total, 'vitesse': float(m[3]),
            'sautees': int(m[4]), 'finie': finie,
            'part': 1.0 if finie else (faites / total if total else 0.0)}


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


def etat_inat(lignes: list[str]) -> dict | None:
    """L'avancée de `inat_corpus.py`, lue sur sa dernière ligne de fragment."""
    m = derniere(lignes, INAT)
    if not m:
        return None
    return {'fragment': int(m[1]), 'fragments': int(m[2]), 'nom': m[3],
            'gardees_fragment': int(m[4]), 'lignes_fragment': int(m[5]),
            'gardees': int(m[6]), 'hors_plantes': int(m[7]), 'deja': int(m[8]),
            'banc': int(m[9]), 'reste_min': int(m[10]),
            'part': int(m[1]) / int(m[2]) if int(m[2]) else 0.0}


def journaux_actifs(racine: Path, maintenant: float | None = None,
                    fenetre: float = 900.0) -> list[Path]:
    """Les journaux `*.log` écrits depuis moins de `fenetre` secondes.

    **Un sujet en cours est un journal qui bouge.** Aucune liste à tenir à
    jour : une passe lancée apparaît dès sa première ligne, une passe finie
    disparaît un quart d'heure après sa dernière — le temps de la voir finir.
    Le quart d'heure couvre la ligne la plus lente qu'on écrive : un fragment
    iNaturalist, téléchargement compris.
    """
    maintenant = maintenant or time.time()
    return sorted(j for j in racine.glob('*.log')
                  if maintenant - j.stat().st_mtime < fenetre)


def erreur_finale(lignes: list[str]) -> str:
    """La dernière erreur du journal si la passe s'est arrêtée dessus, sinon ''.

    Arrêtée *dessus* : la trace doit venir après la dernière ligne de
    progression. Une erreur suivie d'une relance réussie, dans le même
    journal ouvert en `tee -a`, n'est plus un arrêt.
    """
    trace = max((i for i, l in enumerate(lignes) if 'Traceback (most recent call last)' in l),
                default=-1)
    if trace < 0:
        return ''
    motifs = (ENTRAINEMENT, INAT, CACHE, CORPUS)
    progres = max((i for i, l in enumerate(lignes) if any(m.search(l) for m in motifs)),
                  default=-1)
    if progres > trace:
        return ''
    return derniere_ligne(lignes[trace:])


def journaux_arretes(racine: Path, maintenant: float | None = None,
                     fenetre: float = 900.0, memoire: float = 86400.0) -> list[tuple[Path, str]]:
    """Les journaux muets depuis plus de `fenetre`, arrêtés sur une erreur.

    **Une passe qui plante ne doit pas disparaître comme une passe qui a
    fini.** Les deux cessent d'écrire ; seule la trace les distingue. On les
    garde une journée : assez pour la voir au retour, pas assez pour traîner
    la trace d'hier une fois réparée.
    """
    maintenant = maintenant or time.time()
    sortie = []
    for j in sorted(racine.glob('*.log')):
        age = maintenant - j.stat().st_mtime
        if fenetre <= age < memoire:
            e = erreur_finale(lignes(j, 200))
            if e:
                sortie.append((j, e))
    return sortie


def nature(lignes: list[str]) -> str:
    """De quelle sorte de passe un journal parle, d'après ce qu'il écrit.

    Le nom du fichier est libre — c'est celui qu'on a donné à `tee` — alors
    que le format des lignes ne l'est pas.
    """
    for ligne in reversed(lignes):
        if ENTRAINEMENT.search(ligne):
            return 'distillation'
        if INAT.search(ligne):
            return 'inat'
        if CACHE.search(ligne):
            return 'cache'
        if CORPUS.search(ligne):
            return 'corpus'
    return 'autre'


def derniere_ligne(lignes: list[str]) -> str:
    for ligne in reversed(lignes):
        if ligne.strip():
            return ligne.strip()
    return ''


# --------------------------------------------------------------------------
# Les résultats : `voisins.py` sur chaque point de contrôle, sans y penser
# --------------------------------------------------------------------------

# `— indoor — 1127 images`
_TRANCHE = re.compile(r'^— (\S+) —')
# `  texte      à armes égales     top-1 0.6957  top-3 0.8527  (1114/1127 nommables)`
_LIGNE_VOISINS = re.compile(r'^\s+(\S+)\s+(à armes égales|répertoire entier)\s+'
                            r'top-1 ([\d.]+)\s+top-3 ([\d.]+)')

# Les trois lectures qu'on compare depuis le § 19 sexies de docs/14 : ce que
# vaut le student là où Iris 9 existe (armes égales), et là où il n'existe pas.
COLONNES_RESULTAT = (('indoor', 'texte', 'à armes égales'),
                     ('outdoor', 'texte', 'à armes égales'),
                     ('ood_plante', 'texte', 'répertoire entier'))
# Iris 9 masqué, porte C du § 19 de docs/14 ; zéro hors répertoire par construction.
IRIS9 = (0.8119, 0.7615, 0.0)


def lire_voisins(texte: str) -> dict:
    """{tranche: {(références, lecture): top-1}} depuis la sortie de `voisins.py`."""
    sortie, tranche = {}, None
    for ligne in texte.splitlines():
        m = _TRANCHE.match(ligne)
        if m:
            tranche = m[1]
            sortie.setdefault(tranche, {})
            continue
        m = _LIGNE_VOISINS.match(ligne)
        if m and tranche:
            sortie[tranche][(m[1], m[2])] = float(m[3])
    return sortie


def resume(resultats: dict) -> tuple:
    """Les trois chiffres du tableau, None là où la sortie ne les donne pas."""
    return tuple(resultats.get(t, {}).get((r, l)) for t, r, l in COLONNES_RESULTAT)


def etat_evaluation(banc: Path, maintenant: float | None = None,
                    patience: float = 900.0) -> str:
    """`faite`, `en cours`, `échec`, `à faire` — ou `incomplet` si le point de
    contrôle s'écrit encore.

    `index-0.csv` est écrit en dernier par `distiller.py`, après les vecteurs :
    tant qu'il manque, évaluer lirait un banc à moitié encodé.
    """
    if (banc / 'voisins.txt').exists():
        return 'faite'
    if (banc / 'voisins.echec').exists():
        return 'échec'
    partiel = banc / 'voisins.txt.part'
    if partiel.exists() and (maintenant or time.time()) - partiel.stat().st_mtime < patience:
        return 'en cours'
    if not (banc / 'index-0.csv').exists():
        return 'incomplet'
    return 'à faire'


def prochaine_evaluation(bancs: list[Path], maintenant: float | None = None) -> Path | None:
    """Le premier banc à évaluer, ou None si une évaluation tourne déjà.

    **Une à la fois.** Chacune charge les 15 060 références et tient un cœur
    une minute ; les lancer toutes ensemble volerait le processeur au
    décodage des images de la distillation, qui en vit.
    """
    etats = [(b, etat_evaluation(b, maintenant)) for b in bancs]
    if any(e == 'en cours' for _, e in etats):
        return None
    return next((b for b, e in etats if e == 'à faire'), None)


def points(valeur, reference) -> str:
    """`+1,2` ou `−0,8` points d'écart, vide sans référence."""
    if valeur is None or reference is None:
        return ''
    d = (valeur - reference) * 100
    return f' ({"+" if d >= 0 else "−"}{abs(d):.1f})'


def passes_suivies(noms: list[str], sortie: str, log: str,
                   racine: str = '~/plant-data') -> list[tuple[str, str, str]]:
    """(nom, dossier de sortie, journal) pour chaque passe à afficher.

    Toutes les passes de ce dépôt suivent la même convention : sortie dans
    `~/plant-data/<nom>`, journal dans `~/plant-data/<nom>.log`. Donner le nom
    suffit donc, et deux passes enchaînées — l'une qui finit, l'autre qui
    attend son tour — tiennent sur la même page.

    Sans `--passe`, on garde `--sortie` et `--log` tels quels, pour que les
    commandes déjà écrites dans le README continuent de marcher.
    """
    if not noms:
        return [(Path(sortie).name, sortie, log)]
    return [(n, f'{racine}/{n}', f'{racine}/{n}.log') for n in noms]


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
        return f'{chemin} absent — la passe n\'a pas encore commencé'
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


def panneau(nom: str, dossier: str, journal: str, args) -> list[str]:  # pragma: no cover
    """Une passe de distillation : où elle en est, et ce qu'on peut en lire."""
    sortie = Path(dossier).expanduser()
    out = [f'\nDISTILLATION — {nom}']
    etat = sortie / 'etat.json'
    if etat.exists():
        try:
            s = json.loads(etat.read_text())
            out.append(f"  {s.get('student')}, contrastive {s.get('contrastive')}, "
                       f"taux {s.get('calendrier', 'constant')}, "
                       f"{s.get('epoque')} époque(s) bouclée(s)")
        except Exception:
            pass
    e = etat_entrainement(lignes(Path(journal).expanduser()))
    if e is None:
        out.append(f'  {silence(Path(journal).expanduser())}')
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
                   f"--embeddings {dossier}/banc-e{faites[-1]}")
    return out


def tableau(args) -> str:  # pragma: no cover - assemble des lectures disque
    out = [f"── {time.strftime('%H:%M:%S')} ─────────────────────────────────"]
    for nom, dossier, journal in passes_suivies(args.passe, args.sortie, args.log):
        out += panneau(nom, dossier, journal, args)
    sortie = Path(args.sortie).expanduser()

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
    elif c['finie']:
        out.append(f"  {barre(1.0)} terminé — {c['sautees']} sautées")
    else:
        out.append(f"  {barre(c['part'])} {c['part'] * 100:4.1f} %   "
                   f"{c['faites']}/{c['total']}   {c['vitesse']:.1f} img/s")
        out.append(f"  {c['sautees']} sautées   reste "
                   f"{duree(reste(c['faites'], c['total'], c['vitesse']))}")

    carte = gpu()
    if carte:
        out.append(f'\nGPU  {carte}')
    return '\n'.join(out)


def interprete_pour_voisins(courant: str = sys.executable,
                            venv: str = '~/venv-torch/bin/python3',
                            numpy_ici: bool | None = None) -> str:
    """Le Python qui sait lancer `voisins.py`.

    Le tableau n'a besoin que de la bibliothèque standard ; il tourne donc
    aussi dans un terminal où `venv-torch` n'est pas activé. Mais les
    évaluations héritaient de son interprète, et `voisins.py` sans numpy
    échouait — é7 et é8 de la passe du 23 septembre. On garde l'interprète
    courant s'il a numpy, sinon celui du venv s'il existe.
    """
    if numpy_ici is None:
        import importlib.util
        numpy_ici = importlib.util.find_spec('numpy') is not None
    if numpy_ici:
        return courant
    candidat = Path(venv).expanduser()
    return str(candidat) if candidat.exists() else courant


def lancer_evaluation(banc: Path, cache: str) -> None:  # pragma: no cover - processus
    """`voisins.py` en arrière-plan, sortie dans le dossier du banc.

    Écrit dans un `.part` renommé à la fin : un fichier `voisins.txt` présent
    est une évaluation entière. Un échec est renommé aussi, pour ne pas être
    relancé à chaque rafraîchissement. La session est détachée : un Ctrl-C sur
    le tableau n'interrompt pas une évaluation à moitié faite.
    """
    ici = Path(__file__).resolve().parent
    partiel, final, echec = (banc / 'voisins.txt.part', banc / 'voisins.txt',
                             banc / 'voisins.echec')
    commande = (f'{shlex.quote(interprete_pour_voisins())} voisins.py --banc benchmark.csv '
                f'--cache {shlex.quote(str(Path(cache).expanduser()))} '
                f'--embeddings {shlex.quote(str(banc))} > {shlex.quote(str(partiel))} 2>&1 '
                f'&& mv {shlex.quote(str(partiel))} {shlex.quote(str(final))} '
                f'|| mv {shlex.quote(str(partiel))} {shlex.quote(str(echec))}')
    # Le `.part` existe avant que `sh` ait démarré : un rafraîchissement dans
    # la même seconde le voit « en cours » et ne relance pas une seconde fois.
    partiel.touch()
    subprocess.Popen(['sh', '-c', commande], cwd=ici, start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def bancs_de(dossier: Path) -> dict[int, Path]:
    return {n: dossier / f'banc-e{n}' for n in epoques_ecrites(dossier)}


def resultats_de(banc: Path) -> tuple | None:
    if etat_evaluation(banc) != 'faite':
        return None
    return resume(lire_voisins((banc / 'voisins.txt').read_text(encoding='utf-8')))


def panneau_resultats(nom: str, dossier: Path, reference: Path, args) -> list[str]:  # pragma: no cover
    """Le top-1 de chaque époque, à côté de la référence à la même époque."""
    bancs, refs = bancs_de(dossier), ({} if reference == dossier else bancs_de(reference))
    if not bancs:
        return []
    if args.evaluer:
        # l'époque la plus récente d'abord, puis la référence aux mêmes époques
        ordre = [bancs[n] for n in sorted(bancs, reverse=True)]
        ordre += [refs[n] for n in sorted(bancs, reverse=True) if n in refs]
        suivant = prochaine_evaluation(ordre)
        if suivant is not None:
            lancer_evaluation(suivant, args.cache)
    titre = '  top-1, textes      indoor          outdoor         hors rép.'
    out = [titre if reference == dossier else titre + f'      (écart à {reference.name})']
    for n in sorted(bancs):
        r = resultats_de(bancs[n])
        if r is None:
            etat = etat_evaluation(bancs[n])
            if etat == 'échec':
                # la raison tient en une ligne ; sans elle, « échec » ne dit
                # pas quoi réparer. Supprimer `voisins.echec` relance.
                raison = derniere_ligne(lignes(bancs[n] / 'voisins.echec'))[:70]
                etat = f'échec — {raison}'
            out.append(f'  é{n:<3}  {etat}')
            continue
        ref = resultats_de(refs[n]) if n in refs else None
        cellules = [f'{v:.4f}{points(v, ref[i] if ref else None)}' if v is not None else '—'
                    for i, v in enumerate(r)]
        out.append(f'  é{n:<3}  ' + '   '.join(f'{c:<14}' for c in cellules))
    out.append('  Iris 9       ' + '   '.join(f'{v:<14.4f}' for v in IRIS9))
    return out


def tableau_actif(args) -> str:  # pragma: no cover - assemble des lectures disque
    """Tout ce qui tourne en ce moment, et rien de ce qui a fini."""
    racine = Path(args.racine).expanduser()
    out = [f"── {time.strftime('%H:%M:%S')} ─────────────────────────────────"]
    actifs = journaux_actifs(racine, fenetre=args.fenetre)
    for journal in actifs:
        l = lignes(journal)
        sorte, nom = nature(l), journal.stem
        if sorte == 'distillation':
            out += panneau(nom, str(racine / nom), str(journal), args)
            out += panneau_resultats(nom, racine / nom, racine / args.reference, args)
        elif sorte == 'inat':
            i = etat_inat(l)
            out.append(f'\nCORPUS INATURALIST — {nom}')
            out.append(f"  fragment {i['fragment']}/{i['fragments']}   {barre(i['part'])} "
                       f"{i['part'] * 100:4.1f} %   reste {duree(i['reste_min'] * 60)}")
            out.append(f"  {i['gardees']} plantes gardées   {i['hors_plantes']} hors plantes   "
                       f"{i['deja']} déjà au corpus   {i['banc']} écartées pour le banc")
        elif sorte == 'cache':
            k = etat_cache(l)
            out.append(f'\nCACHE TEACHER — {nom}')
            if k['finie']:
                out.append(f"  {barre(1.0)} terminé — {k['total']} vecteurs ajoutés")
            else:
                out.append(f"  {barre(k['part'])} {k['part'] * 100:4.1f} %   "
                           f"{k['fait']}/{k['total']}   {k['vitesse']:.1f} img/s   "
                           f"reste {duree(reste(k['fait'], k['total'], k['vitesse']))}")
        elif sorte == 'corpus':
            c = etat_corpus(l)
            out.append(f'\nCORPUS — {nom}')
            out.append(f"  {barre(c['part'])} {c['part'] * 100:4.1f} %   "
                       f"{c['faites']}/{c['total']}   {c['vitesse']:.1f} img/s")
        else:
            # Une passe qui démarre n'a pas encore écrit sa première ligne de
            # progression : on montre ce qu'elle fait plutôt que rien.
            out.append(f'\n{nom.upper()}')
            out.append(f'  {derniere_ligne(l)[:100]}')
    for journal, e in journaux_arretes(racine, fenetre=args.fenetre):
        depuis = duree(time.time() - journal.stat().st_mtime)
        out.append(f'\nARRÊTÉE — {journal.stem}, depuis {depuis}')
        out.append(f'  {e[:100]}')
        out.append(f'  → tail -n 30 {journal}')
    if not actifs:
        out.append(f"\n  aucun journal de {racine} n'a bougé depuis "
                   f"{duree(args.fenetre)} — rien ne tourne")
    carte = gpu()
    if carte:
        out.append(f'\nGPU  {carte}')
    return '\n'.join(out)


def main() -> int:  # pragma: no cover - boucle d'affichage
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--passe', action='append', default=[], metavar='NOM',
                    help='répétable : suit ~/plant-data/NOM et ~/plant-data/NOM.log')
    ap.add_argument('--sortie', default=None)
    ap.add_argument('--log', default=None)
    ap.add_argument('--racine', default='~/plant-data',
                    help='sans --passe ni --sortie : suit tout journal de ce dossier qui bouge')
    ap.add_argument('--reference', default='iris10-cosinus', metavar='NOM',
                    help='la passe à laquelle chaque époque est comparée')
    ap.add_argument('--sans-evaluation', dest='evaluer', action='store_false',
                    help="n'évalue pas les nouveaux points de contrôle")
    ap.add_argument('--fenetre', type=float, default=900.0, metavar='SECONDES',
                    help="un journal muet depuis plus longtemps est une passe finie")
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


    # Sans rien préciser : tout ce qui tourne, rien de ce qui a fini. Les
    # options d'avant restent pour suivre une passe nommée.
    if args.passe or args.sortie or args.log:
        args.sortie = args.sortie or '~/plant-data/iris10-complet'
        args.log = args.log or '~/plant-data/iris10-complet.log'
        rendre = tableau
    else:
        rendre = tableau_actif
    if not args.boucle:
        print(rendre(args))
        return 0
    try:
        while True:
            print('\033[2J\033[H' + rendre(args), flush=True)
            time.sleep(args.boucle)
    except KeyboardInterrupt:
        return 0


if __name__ == '__main__':
    raise SystemExit(main())
