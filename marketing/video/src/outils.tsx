import React from 'react';
import {
  AbsoluteFill,
  Img,
  continueRender,
  delayRender,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import geometrie from './geometrie.json';

// La palette de l'app (lib/design_system/tokens/colors.dart), celle du kit.
export const C = {
  sauge: '#358354',
  soleil: '#FFE14D',
  eau: '#5DB7FF',
  terracotta: '#FF7B45',
  rose: '#FF8FAB',
  lavande: '#B9A3FF',
  nuit: '#17130F',
  encre: '#1C1712',
  creme: '#FFFBF4',
  blanc: '#FFFFFF',
  sousSauge: '#E2F0E6',
};

// Les polices, chargées avant la première image : sans elles, Chromium
// dessinerait la première seconde dans une police de secours.
const polices: [string, string, string][] = [
  ['Bricolage', 'Bricolage.ttf', '200 800'],
  ['Inter', 'Inter-Medium.ttf', '500'],
  ['Inter', 'Inter-SemiBold.ttf', '600'],
];
const attente = delayRender('polices');
Promise.all(
  polices.map(([famille, fichier, poids]) => {
    const f = new FontFace(famille, `url(${staticFile(fichier)})`, { weight: poids });
    return f.load().then((chargee) => document.fonts.add(chargee));
  }),
).then(() => continueRender(attente));

export const titre = (taille: number, couleur: string = C.encre): React.CSSProperties => ({
  fontFamily: 'Bricolage',
  fontWeight: 800,
  fontVariationSettings: '"opsz" 96',
  fontSize: taille,
  lineHeight: 1.02,
  letterSpacing: -taille * 0.025,
  color: couleur,
});

export const phrase = (taille: number, couleur: string): React.CSSProperties => ({
  fontFamily: 'Inter',
  fontWeight: 500,
  fontSize: taille,
  lineHeight: 1.3,
  color: couleur,
});

// Un ressort réglé une fois pour toute la vidéo : il dépasse un peu, puis
// se pose, comme les pièces de l'app.
export const useRessort = (debut: number, raideur = 170, amorti = 13) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - debut, fps, config: { stiffness: raideur, damping: amorti, mass: 0.9 } });
};

/** L'aplat de la scène et les deux disques pâles des têtes vertes. */
export const Fond: React.FC<{ couleur: string; children?: React.ReactNode }> = ({ couleur, children }) => (
  <AbsoluteFill style={{ backgroundColor: couleur, overflow: 'hidden' }}>
    <div style={disque(1100, -120, 470, 0.1)} />
    <div style={disque(1010, 190, 260, 0.08)} />
    {children}
  </AbsoluteFill>
);

const disque = (cx: number, cy: number, r: number, a: number): React.CSSProperties => ({
  position: 'absolute',
  left: cx - r,
  top: cy - r,
  width: 2 * r,
  height: 2 * r,
  borderRadius: '50%',
  background: `rgba(255,255,255,${a})`,
});

/**
 * Un titre dont les mots tombent un par un, un par temps (ou à la
 * [cadence] donnée). Les retours à la ligne du texte sont gardés.
 */
export const Mots: React.FC<{
  texte: string;
  debut: number;
  cadence?: number;
  taille: number;
  couleur?: string;
  style?: React.CSSProperties;
}> = ({ texte, debut, cadence = 15, taille, couleur = C.encre, style }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  let i = 0;
  return (
    <div style={{ ...titre(taille, couleur), ...style }}>
      {texte.split('\n').map((ligne, l) => (
        <div key={l} style={{ whiteSpace: 'nowrap' }}>
          {ligne.split(' ').map((mot, m) => {
            const k = i++;
            const s = spring({ frame: frame - debut - k * cadence, fps, config: { stiffness: 220, damping: 14 } });
            return (
              <span
                key={m}
                style={{
                  display: 'inline-block',
                  marginRight: '0.24em',
                  opacity: Math.min(1, s * 1.6),
                  transform: `translateY(${(1 - s) * taille * 0.55}px) scale(${0.85 + 0.15 * s})`,
                  transformOrigin: '50% 100%',
                }}
              >
                {mot}
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
};

type NomTel = 'capture' | 'today' | 'diagnosis' | 'plants' | 'garden-calendar';

/**
 * Un téléphone habillé (preparer.py), posé à (x, y) — son coin haut gauche —
 * à la [largeur] donnée. [children] se dessine dans le repère de la capture
 * (sw × sh), par-dessus l'écran.
 */
export const Telephone: React.FC<{
  nom: NomTel;
  largeur: number;
  x: number;
  y: number;
  rotation?: number;
  echelle?: number;
  origine?: string;
  ombre?: boolean;
  children?: React.ReactNode;
}> = ({ nom, largeur, x, y, rotation = 0, echelle = 1, origine = '50% 50%', ombre = true, children }) => {
  const g = geometrie[nom];
  const k = largeur / g.w;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: largeur,
        height: g.h * k,
        transform: `rotate(${rotation}deg) scale(${echelle})`,
        transformOrigin: origine,
        filter: ombre ? 'drop-shadow(0 40px 50px rgba(20,14,8,0.28))' : undefined,
      }}
    >
      <Img src={staticFile(`tel-${nom}.png`)} style={{ width: '100%', height: '100%' }} />
      <div
        style={{
          position: 'absolute',
          left: g.x * k,
          top: g.y * k,
          width: g.sw,
          height: g.sh,
          transform: `scale(${k})`,
          transformOrigin: '0 0',
        }}
      >
        {children}
      </div>
    </div>
  );
};

/**
 * L'entrée d'une scène par-dessus la précédente : un disque qui s'ouvre
 * depuis un point, ou un panneau qui glisse. Dix images, sur le temps fort.
 */
export const Entree: React.FC<{
  type: 'disque' | 'haut' | 'droite';
  x?: number;
  y?: number;
  duree?: number;
  children: React.ReactNode;
}> = ({ type, x = 540, y = 960, duree = 10, children }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [0, duree], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const e = 1 - Math.pow(1 - t, 3);
  let style: React.CSSProperties = {};
  if (type === 'disque') style = { clipPath: `circle(${e * 2300}px at ${x}px ${y}px)` };
  if (type === 'haut') style = { transform: `translateY(${(1 - e) * 1920}px)` };
  if (type === 'droite') style = { transform: `translateX(${(1 - e) * 1080}px)` };
  return <AbsoluteFill style={style}>{children}</AbsoluteFill>;
};

/** Un objet 3D de la collection, avec son ombre. */
export const Objet: React.FC<{ nom: string; taille: number; x: number; y: number; style?: React.CSSProperties }> = ({
  nom,
  taille,
  x,
  y,
  style,
}) => (
  <Img
    src={staticFile(`${nom}.webp`)}
    style={{
      position: 'absolute',
      left: x,
      top: y,
      width: taille,
      height: taille,
      objectFit: 'contain',
      filter: 'drop-shadow(0 26px 22px rgba(20,14,8,0.25))',
      ...style,
    }}
  />
);

/** Une pastille comme celles du kit : l'encre sur les fonds clairs. */
export const Pastille: React.FC<{ texte: string; debut: number; fond?: string; encre?: string; taille?: number }> = ({
  texte,
  debut,
  fond = C.encre,
  encre = C.creme,
  taille = 40,
}) => {
  const s = useRessort(debut, 260, 12);
  return (
    <div
      style={{
        display: 'inline-block',
        fontFamily: 'Inter',
        fontWeight: 600,
        fontSize: taille,
        color: encre,
        background: fond,
        borderRadius: 999,
        padding: `${taille * 0.5}px ${taille * 0.95}px`,
        marginRight: 16,
        marginBottom: 16,
        opacity: Math.min(1, s * 2),
        transform: `scale(${s})`,
        transformOrigin: '0% 50%',
      }}
    >
      {texte}
    </div>
  );
};

export { geometrie };
