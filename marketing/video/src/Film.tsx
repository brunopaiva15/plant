// La vidéo de sortie, en trois actes. La partition (PARTITION.md) donne, temps
// par temps, ce que chaque ligne ci-dessous pose : les temps sont comptés
// de 0 à 51 et convertis en images par t().
//
// La grammaire du mouvement, celle d'un montage After Effects :
// - des courbes exponentielles (sortie rapide, arrivée longue) et non des
//   ressorts qui ballottent ;
// - rien n'est jamais figé : la caméra dérive toujours un peu ;
// - on passe d'un plan à l'autre *à travers* l'image (plongée dans l'écran,
//   feuille qui monte), jamais par un fondu ;
// - chaque geste part un peu avant le temps et touche sur le temps ;
// - le flou de bougé (Racine.tsx) lie les mouvements rapides.
import React from 'react';
import { AbsoluteFill, Easing, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame } from 'remotion';
import { Pot } from './Pot';
import { t } from './temps';
import { C, Objet, geometrie, phrase, titre } from './outils';

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
/** Sortie rapide, arrivée longue : l'« easy ease » poussé d'After Effects. */
const expo = Easing.bezier(0.16, 1, 0.3, 1);
/** Accélère puis freine franchement : les mouvements de caméra. */
const quint = Easing.bezier(0.83, 0, 0.17, 1);
/** Part doucement et file : ce qui sort du cadre. */
const fuite = Easing.bezier(0.7, 0, 0.84, 0);

const anim = (frame: number, de: number, a: number, v0: number, v1: number, easing = expo) =>
  interpolate(frame, [de, a], [v0, v1], { ...clamp, easing });

// --- la grammaire ------------------------------------------------------------------

/** L'étalonnage des plans réels : un peu plus chauds et contrastés, pour
 * qu'ils appartiennent au même film que les aplats. */
const ETALONNAGE = 'contrast(1.07) saturate(1.1) sepia(0.07)';

/** Un plan réel, plein cadre. À la coupe, un coup de zoom et un éclat de
 * lumière de quatre images ; ensuite il avance lentement. */
const Plan: React.FC<{ id: string; debut: number; fin: number; plonge?: number }> = ({ id, debut, fin, plonge }) => {
  const frame = useCurrentFrame();
  if (frame < debut || frame >= fin) return null;
  const coup = anim(frame, debut, debut + 10, 1.14, 1.03);
  const avance = interpolate(frame, [debut + 10, fin], [0, 0.03], clamp);
  const eclat = anim(frame, debut, debut + 5, 1.25, 1);
  // La plongée : la caméra entre dans le plan jusqu'à le traverser.
  const p = plonge === undefined ? 0 : anim(frame, plonge, fin, 0, 1, fuite);
  return (
    <AbsoluteFill style={{ overflow: 'hidden' }}>
      <Sequence from={debut} layout="none">
        <OffthreadVideo
          src={staticFile(`plan-${id}.mp4`)}
          muted
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            transform: `scale(${(coup - avance) * (1 + p * 2.6)})`,
            transformOrigin: '50% 58%',
            filter: `${ETALONNAGE} brightness(${eclat + p * 0.8})`,
          }}
        />
      </Sequence>
    </AbsoluteFill>
  );
};

/** Le voile du haut, sous un titre posé sur une image. */
const Voile: React.FC = () => (
  <AbsoluteFill style={{ background: 'linear-gradient(180deg, rgba(10,8,6,0.6) 0%, rgba(10,8,6,0.22) 28%, rgba(10,8,6,0) 42%)' }} />
);

/** Une ligne qui monte de son masque, et y redescend pour sortir. */
const Ligne: React.FC<{ debut: number; fin?: number; children: React.ReactNode; style?: React.CSSProperties }> = ({
  debut,
  fin,
  children,
  style,
}) => {
  const frame = useCurrentFrame();
  const entre = anim(frame, debut, debut + 14, 1, 0);
  const sort = fin === undefined ? 0 : anim(frame, fin - 8, fin, 0, -1, fuite);
  return (
    <div style={{ overflow: 'hidden', paddingBottom: '0.1em', marginBottom: '-0.1em', ...style }}>
      <div style={{ transform: `translateY(${(entre + sort) * 112}%)` }}>{children}</div>
    </div>
  );
};

/** L'étiquette d'une fonction : le nom, un trait de sa couleur qui se tire,
 * et une ligne dessous. Elle entre par masque et sort par masque. */
const Etiquette: React.FC<{ nom: string; ligne: string; debut: number; fin: number; couleur: string; sous: string; trait: string }> = ({
  nom,
  ligne,
  debut,
  fin,
  couleur,
  sous,
  trait,
}) => {
  const frame = useCurrentFrame();
  if (frame < debut - 1 || frame >= fin) return null;
  const tire = anim(frame, debut + 3, debut + 18, 0, 1) - anim(frame, fin - 8, fin, 0, 1, fuite);
  return (
    <div style={{ position: 'absolute', left: 80, top: 176, width: 900 }}>
      <Ligne debut={debut} fin={fin}>
        <div style={titre(96, couleur)}>{nom}</div>
      </Ligne>
      <div style={{ height: 8, width: 120 * tire, background: trait, borderRadius: 4, margin: '18px 0 16px' }} />
      <Ligne debut={debut + 3} fin={fin - 2}>
        <div style={phrase(38, sous)}>{ligne}</div>
      </Ligne>
    </div>
  );
};

/** Les deux disques pâles des têtes vertes, qui tournent lentement. */
const Disques: React.FC = () => {
  const frame = useCurrentFrame();
  const a = frame / 90;
  return (
    <>
      <div
        style={{
          position: 'absolute',
          left: 1100 - 470 + Math.cos(a) * 18,
          top: -120 - 470 + Math.sin(a) * 18,
          width: 940,
          height: 940,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.1)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 1010 - 260 - Math.cos(a * 1.3) * 14,
          top: 190 - 260 + Math.sin(a * 1.3) * 14,
          width: 520,
          height: 520,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.08)',
        }}
      />
    </>
  );
};

// --- acte 1 : le geste --------------------------------------------------------------

export const Acte1: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.nuit }}>
    <Plan id="4507878" debut={0} fin={t(2)} />
    <Plan id="7421678" debut={t(2)} fin={t(3)} />
    <Plan id="feuilles" debut={t(3)} fin={t(4)} />
    {/* Le cadrage, puis la plongée dans l'écran du téléphone filmé : on en
        ressort dans l'app, sur le temps 8. */}
    <Plan id="6912204" debut={t(4)} fin={t(8)} plonge={t(7.2)} />
    <Voile />
    <div style={{ position: 'absolute', left: 80, top: 176 }}>
      <Ligne debut={-10} fin={t(7.4)}>
        <div style={titre(124, C.blanc)}>Quelle est</div>
      </Ligne>
      <Ligne debut={t(1) - 5} fin={t(7.6)}>
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
const CENTRE_COCHES = vise((COCHES[0][0] + COCHES[1][0]) / 2, COCHES[0][1], 1.3, 540, 1250);
const CENTRE_CARTE = vise(CARTE.x + CARTE.l / 2, CARTE.y + CARTE.h / 2, 1.12, 540, 1120);

// Les images clés de la caméra, en temps. Chaque mouvement dure moins d'un
// temps et touche sur le temps ; entre deux, la dérive tient l'image en vie.
const CAMERA: [number, Pose][] = [
  [8, REPOS],
  [12.2, REPOS],
  [13, vise(NOM[0], NOM[1], 1.62, 540, 1020)],
  [16, vise(NOM[0], NOM[1], 1.62, 540, 1020)],
  [16.01, REPOS],
  [16.4, REPOS],
  [17, CENTRE_COCHES],
  [20.4, CENTRE_COCHES],
  [21.2, REPOS],
  [24.4, REPOS],
  [25.1, CENTRE_CARTE],
  [28.6, CENTRE_CARTE],
  [29.4, REPOS],
];

const pose = (frame: number): Pose => {
  const cles = CAMERA.map(([b, p]) => [t(b), p] as [number, Pose]);
  if (frame <= cles[0][0]) return cles[0][1];
  for (let i = 1; i < cles.length; i++) {
    const [f1, p1] = cles[i];
    const [f0, p0] = cles[i - 1];
    if (frame <= f1) {
      const e = quint((frame - f0) / Math.max(1, f1 - f0));
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
    {voile > 0 && <div style={{ position: 'absolute', inset: 0, background: `rgba(10,8,6,${voile * 0.3})` }} />}
  </div>
);

const TelephoneContinu: React.FC = () => {
  const frame = useCurrentFrame();
  // L'arrivée : il sort de la plongée, en remontant et en se redressant.
  const arrive = anim(frame, t(8), t(8) + 16, 0, 1);
  // Le retour après l'arrosage.
  const retour = anim(frame, t(16), t(16) + 14, 0, 1);
  const entree = frame < t(14) ? arrive : retour;
  const p = pose(frame);
  // La dérive : jamais tout à fait immobile.
  const dx = Math.sin(frame / 47) * 6;
  const dy = Math.sin(frame / 38) * 8;
  const dr = Math.sin(frame / 61) * 0.5;
  // La montée vers le prix, puis la plongée dans l'écran.
  const tension = anim(frame, t(34), t(35.5), 0, 1, Easing.in(Easing.quad));
  const vibre = Math.sin(frame * 2.4) * tension * 8;
  const plonge = anim(frame, t(35.4), t(36), 0, 1, fuite);
  // Quel écran est à l'écran, le poussé en cours, et la bascule du téléphone
  // pendant le poussé (il accompagne le geste, comme tenu en main).
  let actuel = 0;
  ECRANS.forEach(([, b], i) => {
    if (frame >= t(b)) actuel = i;
  });
  const debutPousse = t(ECRANS[actuel][1]) - 2;
  const pousse = actuel > 0 ? anim(frame, debutPousse, debutPousse + 12, 0, 1) : 1;
  const bascule = actuel > 0 ? Math.sin(pousse * Math.PI) * -9 : 0;
  const e = TEL.ecran;
  const scene = (i: number): React.ReactNode => {
    const nom = ECRANS[i][0];
    if (nom === 'capture') return <SurApercu />;
    if (nom === 'today') return <SurAujourdhui />;
    if (nom === 'diagnosis') return <SurDiagnostic />;
    return <SurPlantes />;
  };
  const s = K * p.s * (1 + plonge * 7) * (0.9 + 0.1 * entree);
  // La plongée vise le milieu de l'écran.
  const cx = p.x + (TEL.w * K * p.s) / 2;
  const cy = p.y + (TEL.h * K * p.s) / 2;
  const x = cx + (540 - cx) * plonge - (TEL.w * s) / 2;
  const y = cy + (1000 - cy) * plonge - (TEL.h * s) / 2;
  return (
    <div
      style={{
        position: 'absolute',
        left: x + dx + vibre,
        top: y + dy + (1 - entree) * 1400,
        width: TEL.w,
        height: TEL.h,
        transform: `scale(${s})`,
        transformOrigin: '0 0',
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 0,
          transform: `perspective(5000px) rotateX(${(1 - entree) * 28}deg) rotateY(${bascule}deg) rotate(${p.r + dr}deg)`,
          transformOrigin: '50% 50%',
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
    </div>
  );
};

/** Aperçu : la photo floue, le trait de lumière qui la rend nette, puis un
 * anneau autour du nom posé dessus. */
const SurApercu: React.FC = () => {
  const frame = useCurrentFrame();
  const ph = geometrie.capture.photo;
  const balayage = anim(frame, t(9), t(11), 0, 1, quint);
  const ligne = ph.y + balayage * ph.h;
  const anneau = anim(frame, t(12), t(12) + 18, 0, 1);
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

/** Aujourd'hui : un toucher, puis la coche, sur deux temps qui se suivent. */
const SurAujourdhui: React.FC = () => (
  <>
    <Coche x={COCHES[0][0]} y={COCHES[0][1]} debut={t(18)} />
    <Coche x={COCHES[1][0]} y={COCHES[1][1]} debut={t(19)} />
  </>
);

const Coche: React.FC<{ x: number; y: number; debut: number }> = ({ x, y, debut }) => {
  const frame = useCurrentFrame();
  const doigt = interpolate(frame, [debut - 5, debut, debut + 5], [0, 1, 0], clamp);
  const s = anim(frame, debut, debut + 10, 0, 1, Easing.bezier(0.34, 1.56, 0.64, 1));
  const trait = anim(frame, debut + 2, debut + 10, 0, 1);
  const onde = anim(frame, debut, debut + 16, 0, 1);
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
  const avant = anim(frame, t(25), t(25.8), 0, 1) - anim(frame, t(28.4), t(29.2), 0, 1, quint);
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
  const s = anim(frame, debut - 2, debut + 12, 0, 1);
  const e = TEL.ecran;
  const rayon = geometrie.plants.rayonTuile;
  return (
    <>
      <div style={{ position: 'absolute', left: x - 6, top: y - 6, width: l + 12, height: h + 12, background: '#FFFCF5' }} />
      {s > 0 && (
        <div
          style={{
            position: 'absolute',
            left: x,
            top: y,
            width: l,
            height: h,
            borderRadius: rayon,
            overflow: 'hidden',
            transform: `translateY(${(1 - s) * 160}px) scale(${0.86 + 0.14 * s})`,
            opacity: Math.min(1, s * 3),
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

/** Le fond de l'acte 2 : la couleur de la fonction, qui monte derrière le
 * téléphone depuis le bas à chaque poussé. */
const FONDS: [number, string][] = [
  [8, C.lavande],
  [16, C.eau],
  [24, C.nuit],
  [30, C.rose],
];

const FondActe2: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ overflow: 'hidden' }}>
      {FONDS.map(([b, c], i) => {
        const monte = i === 0 ? 1 : anim(frame, t(b) - 3, t(b) + 12, 0, 1);
        return <AbsoluteFill key={b} style={{ backgroundColor: c, transform: `translateY(${(1 - monte) * 100}%)` }} />;
      })}
      <Disques />
    </AbsoluteFill>
  );
};

export const Acte2: React.FC = () => {
  const frame = useCurrentFrame();
  const eclair = anim(frame, t(8), t(8) + 7, 1, 0);
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
      <Etiquette nom="Identification" ligne="Une photo suffit, même sans réseau." debut={t(8) + 3} fin={t(12.2)} couleur={C.encre} sous={C.encre} trait={C.blanc} />
      <Etiquette
        nom="Soins du jour"
        ligne="Arrosage, engrais, rempotage : à cocher en un geste."
        debut={t(14)}
        fin={t(16.6)}
        couleur={C.blanc}
        sous={C.blanc}
        trait={C.eau}
      />
      <Etiquette nom="Diagnostic sur photo" ligne="Plus de 200 troubles, ravageurs et maladies." debut={t(24)} fin={t(29.8)} couleur={C.blanc} sous="#D6CCC0" trait={C.soleil} />
      <Etiquette nom="Toutes vos plantes" ligne="Avec leur photo, leur espèce et leur pièce." debut={t(30)} fin={t(35.2)} couleur={C.encre} sous={C.encre} trait={C.blanc} />
      <AbsoluteFill style={{ backgroundColor: C.blanc, opacity: frame >= t(8) ? eclair : 0 }} />
    </AbsoluteFill>
  );
};

// --- acte 3 : l'offre et la marque --------------------------------------------------

/** Une pastille qui arrive par la gauche et se pose. */
const Pastille: React.FC<{ texte: string; debut: number }> = ({ texte, debut }) => {
  const frame = useCurrentFrame();
  const s = anim(frame, debut, debut + 12, 0, 1);
  return (
    <div
      style={{
        display: 'inline-block',
        fontFamily: 'Inter',
        fontWeight: 600,
        fontSize: 40,
        color: C.creme,
        background: C.encre,
        borderRadius: 999,
        padding: '20px 38px',
        marginRight: 16,
        marginBottom: 16,
        opacity: Math.min(1, s * 3),
        transform: `translateX(${(1 - s) * -60}px)`,
      }}
    >
      {texte}
    </div>
  );
};

const Prix: React.FC = () => {
  const frame = useCurrentFrame();
  const debut = t(36);
  // Le prix frappe : il arrive grand et flou, et se pose en quatre images.
  const s = anim(frame, debut, debut + 9, 0, 1);
  const d = frame - debut;
  const secousse = d >= 0 && d < 12 ? Math.sin(d * 2.8) * (12 - d) * 2 : 0;
  const pot = anim(frame, t(36.8), t(36.8) + 18, 0, 1);
  // La caméra avance lentement pendant qu'on lit.
  const avance = interpolate(frame, [debut, t(40)], [1, 1.05], clamp);
  return (
    <AbsoluteFill style={{ transform: `translate(${secousse}px, ${secousse * 0.5}px) scale(${avance})` }}>
      <div
        style={{
          position: 'absolute',
          left: 70,
          top: 300,
          ...titre(310),
          transform: `scale(${2.6 - 1.6 * s})`,
          transformOrigin: '20% 60%',
          filter: `blur(${(1 - s) * 18}px)`,
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
      <Objet nom="monstera" taille={620} x={440} y={1090 + (1 - pot) * 800} style={{ transform: `rotate(${(1 - pot) * 14}deg)` }} />
    </AbsoluteFill>
  );
};

const Fin: React.FC = () => {
  const frame = useCurrentFrame();
  const debut = t(40);
  const sous = anim(frame, t(41), t(41) + 14, 0, 1);
  const dispo = anim(frame, t(42), t(42) + 14, 0, 1);
  // La caméra avance jusqu'au bout : la dernière image n'est jamais figée.
  const avance = interpolate(frame, [debut, t(52)], [1, 1.06], clamp);
  return (
    <AbsoluteFill style={{ transform: `scale(${avance})` }}>
      <Sequence from={debut} layout="none">
        <Flotte depart={t(43) - debut}>
          <Pot taille={560} x={540} y={740} arrivee={4} clin={t(46) - debut} />
        </Flotte>
      </Sequence>
      <div style={{ position: 'absolute', top: 1030, width: '100%', textAlign: 'center', ...titre(190, C.blanc) }}>
        {'Auxine'.split('').map((l, i) => (
          <Lettre key={i} l={l} debut={debut + 8 + i * 2} />
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
            opacity: Math.min(1, dispo * 3),
            transform: `translateY(${(1 - dispo) * 40}px) scale(${0.92 + 0.08 * dispo})`,
          }}
        >
          Disponible sur l’App Store.
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Un léger flottement. */
const Flotte: React.FC<{ depart: number; children: React.ReactNode }> = ({ depart, children }) => {
  const frame = useCurrentFrame();
  const d = Math.max(0, frame - depart);
  const a = interpolate(d, [0, 20], [0, 1], clamp);
  return <AbsoluteFill style={{ transform: `translateY(${Math.sin(d / 14) * 10 * a}px)` }}>{children}</AbsoluteFill>;
};

const Lettre: React.FC<{ l: string; debut: number }> = ({ l, debut }) => {
  const frame = useCurrentFrame();
  const s = anim(frame, debut, debut + 14, 0, 1);
  return (
    <span style={{ display: 'inline-block', overflow: 'hidden', verticalAlign: 'bottom' }}>
      <span style={{ display: 'inline-block', transform: `translateY(${(1 - s) * 105}%)` }}>{l}</span>
    </span>
  );
};

/** Le prix apparaît sur la coupe (le téléphone vient de remplir l'image) ;
 * la marque monte ensuite comme une feuille de l'app, par-dessus le prix
 * qui recule. */
export const Acte3: React.FC = () => {
  const frame = useCurrentFrame();
  const feuille = anim(frame, t(40) - 4, t(40) + 12, 0, 1);
  const coins = 90 * (1 - feuille);
  if (frame < t(36)) return null;
  return (
    <>
      <AbsoluteFill style={{ backgroundColor: C.soleil, transform: `translateY(${-feuille * 22}%) scale(${1 - feuille * 0.06})`, filter: `brightness(${1 - feuille * 0.35})` }}>
        <Disques />
        <Prix />
      </AbsoluteFill>
      {frame >= t(40) - 4 && (
        <AbsoluteFill
          style={{
            backgroundColor: C.sauge,
            transform: `translateY(${(1 - feuille) * 100}%)`,
            borderTopLeftRadius: coins,
            borderTopRightRadius: coins,
            overflow: 'hidden',
            boxShadow: '0 -30px 60px rgba(10,8,6,0.25)',
          }}
        >
          <Disques />
          <Fin />
        </AbsoluteFill>
      )}
    </>
  );
};

// --- le film ---------------------------------------------------------------------------

export const Film: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ backgroundColor: C.nuit }}>
      {frame < t(8) + 2 && <Acte1 />}
      {frame >= t(8) && frame < t(36) && <Acte2 />}
      <Acte3 />
    </AbsoluteFill>
  );
};
