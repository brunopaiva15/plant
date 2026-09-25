// La vidéo de sortie, en trois actes. La partition (PARTITION.md) donne, temps
// par temps, ce que chaque ligne ci-dessous pose : les temps sont comptés
// de 0 à 51 et convertis en images par t().
import React from 'react';
import { AbsoluteFill, Easing, Img, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { Pot } from './Pot';
import { t } from './temps';
import { C, Objet, Pastille, geometrie, phrase, titre, useRessort } from './outils';

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
const doux = Easing.inOut(Easing.cubic);

// --- la grammaire ------------------------------------------------------------------

/** L'étalonnage des plans réels : un peu plus chauds et contrastés, pour
 * qu'ils appartiennent au même film que les aplats. */
const ETALONNAGE = 'contrast(1.07) saturate(1.1) sepia(0.07) brightness(1.02)';

/** Un plan réel, plein cadre, avec un petit coup de zoom à la coupe. */
const Plan: React.FC<{ id: string; debut: number; fin: number }> = ({ id, debut, fin }) => {
  const frame = useCurrentFrame();
  if (frame < debut || frame >= fin) return null;
  const coup = interpolate(frame, [debut, debut + 7], [1.1, 1.02], { ...clamp, easing: Easing.out(Easing.cubic) });
  const derive = interpolate(frame, [debut + 7, fin], [1.02, 1], clamp);
  return (
    <AbsoluteFill style={{ overflow: 'hidden' }}>
      <Sequence from={debut} layout="none">
        <OffthreadVideo
          src={staticFile(`plan-${id}.mp4`)}
          muted
          style={{ width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${coup * derive})`, filter: ETALONNAGE }}
        />
      </Sequence>
    </AbsoluteFill>
  );
};

/** Le voile du haut, sous un titre posé sur une image. */
const Voile: React.FC = () => (
  <AbsoluteFill style={{ background: 'linear-gradient(180deg, rgba(10,8,6,0.6) 0%, rgba(10,8,6,0.22) 28%, rgba(10,8,6,0) 42%)' }} />
);

/** Une ligne qui monte de son masque. */
const Ligne: React.FC<{ debut: number; children: React.ReactNode; style?: React.CSSProperties }> = ({ debut, children, style }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - debut, fps, config: { stiffness: 190, damping: 20 } });
  return (
    <div style={{ overflow: 'hidden', paddingBottom: '0.08em', ...style }}>
      <div style={{ transform: `translateY(${(1 - s) * 110}%)` }}>{children}</div>
    </div>
  );
};

/** L'étiquette d'une fonction : le nom, et une ligne dessous. Elle entre par
 * masque et sort en montant. */
const Etiquette: React.FC<{ nom: string; ligne: string; debut: number; fin: number; couleur: string; sous: string }> = ({
  nom,
  ligne,
  debut,
  fin,
  couleur,
  sous,
}) => {
  const frame = useCurrentFrame();
  if (frame < debut || frame >= fin) return null;
  const sortie = interpolate(frame, [fin - 6, fin], [0, 1], clamp);
  return (
    <div style={{ position: 'absolute', left: 80, top: 176, width: 900, opacity: 1 - sortie, transform: `translateY(${-sortie * 40}px)` }}>
      <Ligne debut={debut}>
        <div style={titre(96, couleur)}>{nom}</div>
      </Ligne>
      <Ligne debut={debut + 4} style={{ marginTop: 14 }}>
        <div style={phrase(38, sous)}>{ligne}</div>
      </Ligne>
    </div>
  );
};

/** Un balayage de couleur qui s'ouvre en disque : le passage d'un acte à l'autre. */
const Balayage: React.FC<{ debut: number; x: number; y: number; couleur: string; children: React.ReactNode }> = ({
  debut,
  x,
  y,
  couleur,
  children,
}) => {
  const frame = useCurrentFrame();
  if (frame < debut) return null;
  const e = interpolate(frame, [debut, debut + 10], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  return (
    <AbsoluteFill style={{ clipPath: `circle(${e * 2300}px at ${x}px ${y}px)`, backgroundColor: couleur }}>{children}</AbsoluteFill>
  );
};

// --- acte 1 : le geste --------------------------------------------------------------

export const Acte1: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.nuit }}>
    <Plan id="4507878" debut={0} fin={t(2)} />
    <Plan id="7421678" debut={t(2)} fin={t(3)} />
    <Plan id="feuilles" debut={t(3)} fin={t(4)} />
    <Plan id="6912204" debut={t(4)} fin={t(8) + 2} />
    <Voile />
    <div style={{ position: 'absolute', left: 80, top: 176 }}>
      <Ligne debut={-8}>
        <div style={titre(124, C.blanc)}>Quelle est</div>
      </Ligne>
      <Ligne debut={t(1) - 4}>
        <div style={titre(124, C.blanc)}>cette plante ?</div>
      </Ligne>
    </div>
  </AbsoluteFill>
);

// --- acte 2 : l'app répond ----------------------------------------------------------

const TEL = geometrie.tel;
const LARGEUR = 760;
const K = LARGEUR / TEL.w;
type Pose = { x: number; y: number; s: number; r: number };
const REPOS: Pose = { x: (1080 - LARGEUR) / 2, y: 560, s: 1, r: -2 };

/** La pose qui amène le point (px, py) de l'écran, à l'échelle s, en (cx, cy). */
const vise = (px: number, py: number, s: number, cx: number, cy: number): Pose => ({
  x: cx - (TEL.ecran.x + px) * K * s,
  y: cy - (TEL.ecran.y + TEL.haut + py) * K * s,
  s,
  r: 0,
});

const NOM = geometrie.capture.nom;
const COCHES = geometrie.today.coches;
const CARTE = geometrie.diagnosis.carte;
const TUILES = geometrie.plants.tuiles;

// Les images clés de la caméra, en temps.
const CAMERA: [number, Pose][] = [
  [8, REPOS],
  [12, REPOS],
  [13.2, vise(NOM[0], NOM[1], 1.6, 540, 1020)],
  [14, vise(NOM[0], NOM[1], 1.66, 540, 1020)],
  [16, REPOS],
  [16.4, REPOS],
  [17.4, vise((COCHES[0][0] + COCHES[1][0]) / 2, COCHES[0][1], 1.3, 540, 1250)],
  [21.6, vise((COCHES[0][0] + COCHES[1][0]) / 2, COCHES[0][1], 1.34, 540, 1250)],
  [22.8, REPOS],
  [24.6, REPOS],
  [25.6, vise(CARTE.x + CARTE.l / 2, CARTE.y + CARTE.h / 2, 1.12, 540, 1120)],
  [28.4, vise(CARTE.x + CARTE.l / 2, CARTE.y + CARTE.h / 2, 1.14, 540, 1120)],
  [29.4, REPOS],
  [34, REPOS],
  [36, { ...REPOS, s: 1.1, x: REPOS.x - 38, y: REPOS.y - 40 }],
];

const pose = (frame: number): Pose => {
  const cles = CAMERA.map(([b, p]) => [t(b), p] as [number, Pose]);
  if (frame <= cles[0][0]) return cles[0][1];
  for (let i = 1; i < cles.length; i++) {
    const [f1, p1] = cles[i];
    const [f0, p0] = cles[i - 1];
    if (frame <= f1) {
      const e = doux((frame - f0) / Math.max(1, f1 - f0));
      return { x: p0.x + (p1.x - p0.x) * e, y: p0.y + (p1.y - p0.y) * e, s: p0.s + (p1.s - p0.s) * e, r: p0.r + (p1.r - p0.r) * e };
    }
  }
  return cles[cles.length - 1][1];
};

// Les écrans, et le temps où chacun est poussé.
const ECRANS: [string, number][] = [
  ['capture', 8],
  ['today', 16],
  ['diagnosis', 24],
  ['plants', 30],
];

const Ecran: React.FC<{ nom: string; decalage: number; voile: number; children?: React.ReactNode }> = ({
  nom,
  decalage,
  voile,
  children,
}) => (
  <div style={{ position: 'absolute', inset: 0, transform: `translateX(${decalage * 100}%)` }}>
    <Img src={staticFile(`ecran-${nom}.jpg`)} style={{ width: '100%', height: '100%' }} />
    <div style={{ position: 'absolute', left: 0, top: TEL.haut, width: TEL.ecran.l, height: TEL.ecran.h - TEL.haut }}>{children}</div>
    {voile > 0 && <div style={{ position: 'absolute', inset: 0, background: `rgba(10,8,6,${voile * 0.25})` }} />}
  </div>
);

const TelephoneContinu: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const monte = spring({ frame: frame - t(8), fps, config: { stiffness: 170, damping: 17 } });
  const p = pose(frame);
  // La montée vers le prix : le téléphone vibre de plus en plus.
  const tension = interpolate(frame, [t(34), t(36)], [0, 1], clamp);
  const vibre = Math.sin(frame * 2.4) * tension * tension * 9;
  // Quel écran est à l'écran, et le poussé en cours.
  let actuel = 0;
  ECRANS.forEach(([, b], i) => {
    if (frame >= t(b)) actuel = i;
  });
  const pousse = actuel > 0 ? interpolate(frame, [t(ECRANS[actuel][1]), t(ECRANS[actuel][1]) + 9], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) }) : 1;
  const e = TEL.ecran;
  const scene = (i: number): React.ReactNode => {
    const nom = ECRANS[i][0];
    if (nom === 'capture') return <SurApercu />;
    if (nom === 'today') return <SurAujourdhui />;
    if (nom === 'diagnosis') return <SurDiagnostic />;
    return <SurPlantes />;
  };
  return (
    <div
      style={{
        position: 'absolute',
        left: p.x + vibre,
        top: p.y + (1 - monte) * 1500,
        width: TEL.w,
        height: TEL.h,
        transform: `scale(${K * p.s}) rotate(${p.r}deg)`,
        transformOrigin: '0 0',
        filter: 'drop-shadow(0 70px 80px rgba(20,14,8,0.3))',
      }}
    >
      <div style={{ position: 'absolute', left: e.x, top: e.y, width: e.l, height: e.h, borderRadius: e.rayon, overflow: 'hidden', background: C.creme }}>
        {actuel > 0 && pousse < 1 && (
          <Ecran nom={ECRANS[actuel - 1][0]} decalage={-0.3 * pousse} voile={pousse}>
            {scene(actuel - 1)}
          </Ecran>
        )}
        <Ecran nom={ECRANS[actuel][0]} decalage={1 - pousse} voile={0}>
          {scene(actuel)}
        </Ecran>
      </div>
      <Img src={staticFile('cadre.png')} style={{ position: 'absolute', left: 0, top: 0, width: TEL.w, height: TEL.h }} />
    </div>
  );
};

/** Aperçu : la photo floue, le trait de lumière qui la rend nette, puis un
 * anneau autour du nom posé dessus. */
const SurApercu: React.FC = () => {
  const frame = useCurrentFrame();
  const ph = geometrie.capture.photo;
  const balayage = interpolate(frame, [t(9), t(11)], [0, 1], { ...clamp, easing: doux });
  const ligne = ph.y + balayage * ph.h;
  const anneau = interpolate(frame, [t(12), t(12) + 16], [0, 1], clamp);
  return (
    <>
      <div
        style={{
          position: 'absolute',
          left: ph.x,
          top: ligne,
          width: ph.l,
          height: Math.max(0, ph.y + ph.h - ligne),
          backdropFilter: 'blur(30px) saturate(0.7)',
          background: 'rgba(28,23,18,0.16)',
          borderBottomLeftRadius: ph.rayon,
          borderBottomRightRadius: ph.rayon,
        }}
      />
      {balayage > 0 && balayage < 1 && (
        <div
          style={{
            position: 'absolute',
            left: ph.x,
            top: ligne - 7,
            width: ph.l,
            height: 14,
            borderRadius: 7,
            background: C.blanc,
            boxShadow: '0 0 50px 20px rgba(255,255,255,0.8)',
          }}
        />
      )}
      {anneau > 0 && anneau < 1 && (
        <div
          style={{
            position: 'absolute',
            left: NOM[0] - 190 - anneau * 60,
            top: NOM[1] - 95 - anneau * 40,
            width: 380 + anneau * 120,
            height: 190 + anneau * 80,
            borderRadius: 70,
            border: `10px solid ${C.blanc}`,
            opacity: 1 - anneau,
          }}
        />
      )}
    </>
  );
};

/** Aujourd'hui : un toucher, puis la coche, sur deux tuiles. */
const SurAujourdhui: React.FC = () => (
  <>
    <Coche x={COCHES[0][0]} y={COCHES[0][1]} debut={t(18)} />
    <Coche x={COCHES[1][0]} y={COCHES[1][1]} debut={t(20)} />
  </>
);

const Coche: React.FC<{ x: number; y: number; debut: number }> = ({ x, y, debut }) => {
  const frame = useCurrentFrame();
  const doigt = interpolate(frame, [debut - 6, debut, debut + 6], [0, 1, 0], clamp);
  const s = useRessort(debut, 300, 14);
  const trait = interpolate(frame, [debut + 2, debut + 9], [0, 1], clamp);
  const onde = interpolate(frame, [debut, debut + 14], [0, 1], clamp);
  const r = 50;
  return (
    <>
      {doigt > 0 && (
        <div
          style={{
            position: 'absolute',
            left: x - 90,
            top: y - 90,
            width: 180,
            height: 180,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.55)',
            transform: `scale(${0.6 + 0.4 * doigt})`,
            opacity: doigt,
          }}
        />
      )}
      {frame >= debut && (
        <>
          <div
            style={{
              position: 'absolute',
              left: x - r * (1 + onde * 1.6),
              top: y - r * (1 + onde * 1.6),
              width: 2 * r * (1 + onde * 1.6),
              height: 2 * r * (1 + onde * 1.6),
              borderRadius: '50%',
              border: `8px solid ${C.sauge}`,
              opacity: 1 - onde,
            }}
          />
          <svg width={2 * r} height={2 * r} viewBox="0 0 100 100" style={{ position: 'absolute', left: x - r, top: y - r, transform: `scale(${s})` }}>
            <circle cx={50} cy={50} r={50} fill={C.sauge} />
            <path
              d="M28 52 L44 67 L73 36"
              fill="none"
              stroke={C.blanc}
              strokeWidth={10}
              strokeLinecap="round"
              strokeLinejoin="round"
              pathLength={1}
              strokeDasharray={1}
              strokeDashoffset={1 - trait}
            />
          </svg>
        </>
      )}
    </>
  );
};

/** Diagnostic : la carte « Air trop sec » passe au premier plan, le reste s'efface. */
const SurDiagnostic: React.FC = () => {
  const frame = useCurrentFrame();
  const avant = interpolate(frame, [t(25), t(25.8), t(28.2), t(29)], [0, 1, 1, 0], clamp);
  if (avant <= 0) return null;
  return (
    <div
      style={{
        position: 'absolute',
        left: CARTE.x,
        top: CARTE.y,
        width: CARTE.l,
        height: CARTE.h,
        borderRadius: CARTE.rayon,
        boxShadow: `0 0 0 4000px rgba(10,8,6,${0.42 * avant}), 0 0 0 ${10 * avant}px ${C.soleil}`,
      }}
    />
  );
};

/** Plantes : les deux premières tuiles arrivent sur deux temps. */
const SurPlantes: React.FC = () => (
  <>
    {TUILES.map(([x, y, l, h], i) => (
      <Tuile key={i} x={x} y={y} l={l} h={h} debut={t(31 + i)} />
    ))}
  </>
);

const Tuile: React.FC<{ x: number; y: number; l: number; h: number; debut: number }> = ({ x, y, l, h, debut }) => {
  const frame = useCurrentFrame();
  const s = useRessort(debut, 260, 13);
  const e = TEL.ecran;
  const rayon = geometrie.plants.rayonTuile;
  // Avant son temps, la tuile est cachée sous le fond de la grille.
  return (
    <>
      <div style={{ position: 'absolute', left: x - 6, top: y - 6, width: l + 12, height: h + 12, background: '#FFFCF5' }} />
      {frame >= debut && (
        <div
          style={{
            position: 'absolute',
            left: x,
            top: y,
            width: l,
            height: h,
            borderRadius: rayon,
            overflow: 'hidden',
            transform: `scale(${0.8 + 0.2 * s})`,
            opacity: Math.min(1, s * 2),
            boxShadow: '0 20px 40px rgba(20,14,8,0.18)',
          }}
        >
          <Img
            src={staticFile('ecran-plants.jpg')}
            style={{ position: 'absolute', left: -x, top: -(y + TEL.haut), width: e.l, height: e.h, maxWidth: 'none' }}
          />
        </div>
      )}
    </>
  );
};

/** Le fond de l'acte 2 : la couleur de la fonction, fondue d'une à l'autre. */
const FONDS: [number, string][] = [
  [8, C.lavande],
  [16, C.eau],
  [24, C.nuit],
  [30, C.rose],
];

const FondActe2: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      {FONDS.map(([b, c], i) => {
        const o = i === 0 ? 1 : interpolate(frame, [t(b), t(b) + 8], [0, 1], clamp);
        return <AbsoluteFill key={b} style={{ backgroundColor: c, opacity: o }} />;
      })}
      <div style={{ position: 'absolute', left: 1100 - 470, top: -120 - 470, width: 940, height: 940, borderRadius: '50%', background: 'rgba(255,255,255,0.1)' }} />
      <div style={{ position: 'absolute', left: 1010 - 260, top: 190 - 260, width: 520, height: 520, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }} />
    </AbsoluteFill>
  );
};

export const Acte2: React.FC = () => {
  const frame = useCurrentFrame();
  const eclair = interpolate(frame, [t(8), t(8) + 6], [0.95, 0], clamp);
  const arrosage = frame >= t(14) && frame < t(16);
  return (
    <AbsoluteFill>
      <FondActe2 />
      {!arrosage && <TelephoneContinu />}
      {arrosage && (
        <>
          <Plan id="7218427" debut={t(14)} fin={t(16)} />
          <Voile />
        </>
      )}
      <Etiquette nom="Identification" ligne="Une photo suffit, même sans réseau." debut={t(8) + 2} fin={t(12.2)} couleur={C.encre} sous={C.encre} />
      <Etiquette
        nom="Soins du jour"
        ligne="Arrosage, engrais, rempotage : à cocher en un geste."
        debut={t(14)}
        fin={t(17)}
        couleur={arrosage ? C.blanc : C.encre}
        sous={arrosage ? C.blanc : C.encre}
      />
      <Etiquette nom="Diagnostic sur photo" ligne="Plus de 200 troubles, ravageurs et maladies." debut={t(24)} fin={t(30)} couleur={C.blanc} sous="#D6CCC0" />
      <Etiquette nom="Toutes vos plantes" ligne="Avec leur photo, leur espèce et leur pièce." debut={t(30)} fin={t(36)} couleur={C.encre} sous={C.encre} />
      <AbsoluteFill style={{ backgroundColor: C.blanc, opacity: frame >= t(8) ? eclair : 0 }} />
    </AbsoluteFill>
  );
};

// --- acte 3 : l'offre et la marque --------------------------------------------------

const Prix: React.FC = () => {
  const frame = useCurrentFrame();
  const debut = t(36);
  const s = useRessort(debut, 420, 18);
  const d = frame - debut;
  const secousse = d >= 0 && d < 10 ? Math.sin(d * 3.1) * (10 - d) * 2.4 : 0;
  const pot = useRessort(t(36.6), 140, 14);
  return (
    <AbsoluteFill style={{ transform: `translate(${secousse}px, ${secousse * 0.6}px)` }}>
      <div
        style={{
          position: 'absolute',
          left: 70,
          top: 300,
          ...titre(310),
          transform: `scale(${2.4 - 1.4 * s})`,
          transformOrigin: '20% 60%',
          filter: `blur(${(1 - Math.min(1, s)) * 14}px)`,
        }}
      >
        0,99 €
      </div>
      <div style={{ position: 'absolute', left: 84, top: 660 }}>
        <Ligne debut={t(37)}>
          <div style={titre(92)}>Un seul achat.</div>
        </Ligne>
        <Ligne debut={t(37.5)}>
          <div style={titre(92)}>Sans abonnement.</div>
        </Ligne>
      </div>
      <div style={{ position: 'absolute', left: 84, top: 920, width: 880 }}>
        <Pastille texte="Toutes les fonctions" debut={t(38)} />
        <Pastille texte="Sans publicité" debut={t(38.5)} />
        <Pastille texte="Sans achat intégré" debut={t(39)} />
      </div>
      <Objet nom="monstera" taille={620} x={440} y={1090 + (1 - pot) * 700} style={{ transform: `rotate(${(1 - pot) * 20}deg)` }} />
    </AbsoluteFill>
  );
};

const Fin: React.FC = () => {
  const debut = t(40);
  const sous = useRessort(t(41), 200, 16);
  const dispo = useRessort(t(42), 220, 13);
  return (
    <AbsoluteFill>
      <Sequence from={debut} layout="none">
        <Flotte depart={t(43) - debut}>
          <Pot taille={560} x={540} y={740} arrivee={0} clin={t(46) - debut} />
        </Flotte>
      </Sequence>
      <div style={{ position: 'absolute', top: 1030, width: '100%', textAlign: 'center', ...titre(190, C.blanc) }}>
        {'Auxine'.split('').map((l, i) => (
          <Lettre key={i} l={l} debut={debut + 6 + i * 2} />
        ))}
      </div>
      <div
        style={{
          position: 'absolute',
          top: 1250,
          width: '100%',
          textAlign: 'center',
          opacity: sous,
          transform: `translateY(${(1 - sous) * 30}px)`,
          ...phrase(46, C.sousSauge),
        }}
      >
        Le carnet de vos plantes.
      </div>
      <div style={{ position: 'absolute', top: 1340, width: '100%', textAlign: 'center' }}>
        <div
          style={{
            display: 'inline-block',
            fontFamily: 'Inter',
            fontWeight: 600,
            fontSize: 44,
            color: C.encre,
            background: C.blanc,
            borderRadius: 999,
            padding: '24px 44px',
            opacity: Math.min(1, dispo * 2),
            transform: `scale(${dispo})`,
          }}
        >
          Disponible sur l’App Store.
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Un léger flottement, pour que la dernière image ne soit jamais figée. */
const Flotte: React.FC<{ depart: number; children: React.ReactNode }> = ({ depart, children }) => {
  const frame = useCurrentFrame();
  const d = Math.max(0, frame - depart);
  const a = interpolate(d, [0, 20], [0, 1], clamp);
  return <AbsoluteFill style={{ transform: `translateY(${Math.sin(d / 14) * 10 * a}px)` }}>{children}</AbsoluteFill>;
};

const Lettre: React.FC<{ l: string; debut: number }> = ({ l, debut }) => {
  const s = useRessort(debut, 260, 12);
  return <span style={{ display: 'inline-block', opacity: Math.min(1, s * 2), transform: `translateY(${(1 - s) * 95}px)` }}>{l}</span>;
};

const Disques: React.FC = () => (
  <>
    <div style={{ position: 'absolute', left: 1100 - 470, top: -120 - 470, width: 940, height: 940, borderRadius: '50%', background: 'rgba(255,255,255,0.1)' }} />
    <div style={{ position: 'absolute', left: 1010 - 260, top: 190 - 260, width: 520, height: 520, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }} />
  </>
);

export const Acte3: React.FC = () => (
  <>
    <Balayage debut={t(36)} x={540} y={1150} couleur={C.soleil}>
      <Disques />
      <Prix />
    </Balayage>
    <Balayage debut={t(40)} x={300} y={520} couleur={C.sauge}>
      <Disques />
      <Fin />
    </Balayage>
  </>
);

// --- le film ---------------------------------------------------------------------------

export const Film: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ backgroundColor: C.nuit }}>
      {frame < t(8) + 8 && <Acte1 />}
      {frame >= t(8) && frame < t(36) + 12 && <Acte2 />}
      <Acte3 />
    </AbsoluteFill>
  );
};
