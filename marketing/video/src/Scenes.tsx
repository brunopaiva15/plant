import React from 'react';
import { AbsoluteFill, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame, Easing } from 'remotion';
import { Pot } from './Pot';
import { TEMPS, t } from './temps';
import { C, Entree, Fond, Mots, Objet, Pastille, Telephone, geometrie, phrase, titre, useRessort } from './outils';

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;

// --- 1. Les plans réels ------------------------------------------------------------
// Trois plans filmés en intérieur (Pexels), coupés sur les temps : un
// téléphone qui photographie des plantes, des succulentes vues de dessus, des
// mains autour d'un pot. « Le carnet de vos plantes. » s'écrit par-dessus.
const PLANS_ACCROCHE: [string, number, number][] = [
  ['7872725', 0, 3],
  ['4507878', 3, 6],
  ['7421678', 6, 9],
];

/** Un plan réel, plein cadre, qui avance d'un léger zoom. */
export const Plan: React.FC<{ id: string; debut: number; fin: number }> = ({ id, debut, fin }) => {
  const frame = useCurrentFrame();
  if (frame < debut || frame >= fin) return null;
  const k = interpolate(frame, [debut, fin], [1.08, 1], clamp);
  return (
    <AbsoluteFill style={{ overflow: 'hidden' }}>
      <Sequence from={debut} layout="none">
        <OffthreadVideo src={staticFile(`plan-${id}.mp4`)} muted style={{ width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${k})` }} />
      </Sequence>
    </AbsoluteFill>
  );
};

/** Le voile du haut, pour que le titre se lise sur une image. */
const Voile: React.FC = () => (
  <AbsoluteFill style={{ background: 'linear-gradient(180deg, rgba(10,8,6,0.62) 0%, rgba(10,8,6,0.25) 30%, rgba(10,8,6,0) 45%)' }} />
);

export const ScenePhotos: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: C.nuit }}>
    {PLANS_ACCROCHE.map(([id, a, b]) => (
      <Plan key={id} id={id} debut={t(a)} fin={t(b) + 16} />
    ))}
    <Voile />
    <Mots texte={'Le carnet\nde vos plantes.'} debut={-5} taille={124} couleur={C.blanc} style={{ position: 'absolute', left: 80, top: 190 }} />
  </AbsoluteFill>
);

// --- 2. Le pot --------------------------------------------------------------------
// Le premier temps fort : le pot de l'icône se pose, cligne de l'œil, et le
// nom s'écrit dessous, lettre par lettre.
export const ScenePot: React.FC = () => (
  <Entree type="disque" x={540} y={1080}>
    <Fond couleur={C.sauge}>
      <Pot taille={640} x={540} y={820} arrivee={0} clin={t(2)} />
      <Lettres texte="Auxine" debut={6} taille={200} couleur={C.blanc} y={1150} />
    </Fond>
  </Entree>
);

const Lettres: React.FC<{ texte: string; debut: number; taille: number; couleur: string; y: number }> = ({
  texte,
  debut,
  taille,
  couleur,
  y,
}) => (
  <div style={{ position: 'absolute', top: y, width: '100%', textAlign: 'center', ...titre(taille, couleur) }}>
    {texte.split('').map((l, i) => (
      <Lettre key={i} l={l} debut={debut + i * 2} taille={taille} />
    ))}
  </div>
);

const Lettre: React.FC<{ l: string; debut: number; taille: number }> = ({ l, debut, taille }) => {
  const s = useRessort(debut, 260, 12);
  return (
    <span
      style={{
        display: 'inline-block',
        opacity: Math.min(1, s * 2),
        transform: `translateY(${(1 - s) * taille * 0.5}px)`,
      }}
    >
      {l}
    </span>
  );
};

// --- 3. Iris ------------------------------------------------------------------------
// L'étape « Aperçu » : la photo est d'abord floue, un trait de lumière la
// parcourt, et derrière lui l'image devient nette — avec les noms posés
// dessus. Puis la caméra s'approche de « Figuier lyre ».
// La photo et le nom posé dessus, mesurés par preparer.py sur la capture.
const APERCU = geometrie.capture;
const PHOTO_APERCU = APERCU.photo;
// La caméra s'approche du nom : l'origine du zoom, dans le téléphone.
const ORIGINE_NOM = `${((APERCU.x + APERCU.nom[0]) / APERCU.w) * 100}% ${((APERCU.y + APERCU.nom[1]) / APERCU.h) * 100}%`;

export const SceneIris: React.FC = () => {
  const frame = useCurrentFrame();
  // Deux mesures : le plan réel jusqu'au déclenchement (temps 4), puis l'app.
  const coupe = t(4);
  const monte = useRessort(coupe, 170, 16);
  const balayage = interpolate(frame, [t(4.4), t(6.2)], [0, 1], { ...clamp, easing: Easing.inOut(Easing.cubic) });
  const approche = interpolate(frame, [t(6.5), t(7.9)], [0, 1], { ...clamp, easing: Easing.inOut(Easing.cubic) });
  const eclair = interpolate(frame, [coupe, coupe + 5], [0.9, 0], clamp);
  const p = PHOTO_APERCU;
  const ligne = p.y + balayage * p.h;
  const reel = frame < coupe;
  return (
    <Entree type="haut">
      <Fond couleur={C.lavande}>
        {reel && (
          <>
            <Plan id="6912204" debut={0} fin={coupe} />
            <Voile />
          </>
        )}
        <Mots texte={'Quelle est\ncette plante ?'} debut={4} taille={124} couleur={reel ? C.blanc : C.encre} style={{ position: 'absolute', left: 80, top: 190 }} />
        {!reel && (
          <Telephone
            nom="capture"
            largeur={800}
            x={140}
            y={560 + (1 - monte) * 1100}
            rotation={-3 + 3 * approche}
            echelle={1 + 0.55 * approche}
            origine={ORIGINE_NOM}
          >
            {/* Le flou, sous le trait : il ne couvre que ce que le trait n'a pas encore passé. */}
            <div
              style={{
                position: 'absolute',
                left: p.x,
                top: ligne,
                width: p.l,
                height: Math.max(0, p.y + p.h - ligne),
                backdropFilter: 'blur(26px) saturate(0.7)',
                background: 'rgba(28,23,18,0.18)',
                borderBottomLeftRadius: p.rayon,
                borderBottomRightRadius: p.rayon,
              }}
            />
            {balayage > 0 && balayage < 1 && (
              <div
                style={{
                  position: 'absolute',
                  left: p.x,
                  top: ligne - 6,
                  width: p.l,
                  height: 12,
                  borderRadius: 6,
                  background: C.blanc,
                  boxShadow: '0 0 40px 16px rgba(255,255,255,0.75)',
                }}
              />
            )}
          </Telephone>
        )}
        {/* L'éclair du déclenchement, sur la coupe. */}
        <AbsoluteFill style={{ backgroundColor: C.blanc, opacity: frame >= coupe ? eclair : 0 }} />
      </Fond>
    </Entree>
  );
};

// --- 4. Les soins -------------------------------------------------------------------
// L'écran Aujourd'hui. À la deuxième mesure, la caméra descend vers les
// tuiles « À venir », et leurs ronds se cochent sur deux temps.
const JOUR = geometrie.today;
const K_JOUR = 800 / JOUR.w;
const Y_COCHES = (JOUR.y + JOUR.coches[0][1]) * K_JOUR;
const ORIGINE_COCHES = `50% ${((JOUR.y + JOUR.coches[0][1]) / JOUR.h) * 100}%`;

export const SceneSoins: React.FC = () => {
  const frame = useCurrentFrame();
  const entre = useRessort(0, 150, 16);
  const descend = interpolate(frame, [t(3.47), t(4.53)], [0, 1], { ...clamp, easing: Easing.inOut(Easing.cubic) });
  return (
    <Entree type="droite">
      <Fond couleur={C.eau}>
        <div style={{ opacity: 1 - descend, transform: `translateY(${-descend * 120}px)` }}>
          <Mots texte={'Chaque matin,\nles soins du jour.'} debut={4} taille={112} style={{ position: 'absolute', left: 80, top: 190 }} />
        </div>
        <Telephone
          nom="today"
          largeur={800}
          x={140 + (1 - entre) * 700}
          y={560 - descend * (560 + Y_COCHES - 1150)}
          rotation={-4 * (1 - descend)}
          echelle={1 + 0.3 * descend}
          origine={ORIGINE_COCHES}
        >
          <Coche x={JOUR.coches[0][0]} y={JOUR.coches[0][1]} debut={t(5)} />
          <Coche x={JOUR.coches[1][0]} y={JOUR.coches[1][1]} debut={t(6)} />
        </Telephone>
      </Fond>
    </Entree>
  );
};

/** Le rond de validation d'une tuile, qui se remplit et se coche. */
const Coche: React.FC<{ x: number; y: number; debut: number }> = ({ x, y, debut }) => {
  const frame = useCurrentFrame();
  const s = useRessort(debut, 300, 14);
  const trait = interpolate(frame, [debut + 2, debut + 9], [0, 1], clamp);
  const onde = interpolate(frame, [debut, debut + 14], [0, 1], clamp);
  if (frame < debut) return null;
  const r = 50;
  return (
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
      <svg
        width={2 * r}
        height={2 * r}
        viewBox="0 0 100 100"
        style={{ position: 'absolute', left: x - r, top: y - r, transform: `scale(${s})` }}
      >
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
  );
};

// --- 5. Le diagnostic -------------------------------------------------------------
export const SceneDiagnostic: React.FC = () => {
  const entre = useRessort(0, 140, 15);
  const frame = useCurrentFrame();
  const derive = interpolate(frame, [0, t(4.67)], [0, 1], clamp);
  const sous = useRessort(t(2), 200, 16);
  return (
    <Entree type="disque" x={760} y={1150}>
      <Fond couleur={C.nuit}>
        <Mots texte={'Un diagnostic\nsur photo.'} debut={0} cadence={TEMPS / 2} taille={124} couleur={C.blanc} style={{ position: 'absolute', left: 80, top: 190 }} />
        <div
          style={{
            position: 'absolute',
            left: 80,
            top: 470,
            width: 860,
            opacity: sous,
            transform: `translateY(${(1 - sous) * 30}px)`,
            ...phrase(42, '#D6CCC0'),
          }}
        >
          Plus de 200 troubles, ravageurs et maladies.
        </div>
        <Telephone
          nom="diagnosis"
          largeur={780}
          x={220 + (1 - entre) * 900}
          y={640 - derive * 60}
          rotation={5 - 2 * entre}
        />
      </Fond>
    </Entree>
  );
};

// --- 6. La collection ---------------------------------------------------------------
export const SceneCollection: React.FC = () => {
  const frame = useCurrentFrame();
  const a = useRessort(0, 150, 15);
  const b = useRessort(t(1), 150, 15);
  // Le roulement de la fin de mesure : les deux écrans vibrent de plus en plus.
  const tension = interpolate(frame, [t(2), t(4)], [0, 1], clamp);
  const vibre = Math.sin(frame * 2.3) * tension * 7;
  return (
    <Entree type="haut">
      <Fond couleur={C.rose}>
        <Mots texte={'Toutes vos plantes,\nau même endroit.'} debut={0} cadence={TEMPS * 0.4} taille={100} style={{ position: 'absolute', left: 80, top: 190 }} />
        <Telephone nom="plants" largeur={560} x={50 + vibre} y={640 + (1 - a) * 1300} rotation={-6} />
        <Telephone nom="garden-calendar" largeur={560} x={470 - vibre} y={720 + (1 - b) * 1300} rotation={5} />
      </Fond>
    </Entree>
  );
};

// --- 7. Le prix ---------------------------------------------------------------------
export const ScenePrix: React.FC = () => {
  const frame = useCurrentFrame();
  const s = useRessort(0, 420, 18);
  const secousse = frame < 10 ? Math.sin(frame * 3.1) * (10 - frame) * 2.4 : 0;
  const l1 = useRessort(t(0.5), 220, 15);
  const l2 = useRessort(t(1), 220, 15);
  const pot = useRessort(t(1.33), 140, 14);
  return (
    <Entree type="disque" x={540} y={560} duree={6}>
      <Fond couleur={C.soleil}>
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
          <div style={{ position: 'absolute', left: 84, top: 660, ...titre(92) }}>
            <div style={{ opacity: l1, transform: `translateX(${(1 - l1) * -80}px)` }}>Un seul achat.</div>
            <div style={{ opacity: l2, transform: `translateX(${(1 - l2) * -80}px)` }}>Sans abonnement.</div>
          </div>
          <div style={{ position: 'absolute', left: 84, top: 920, width: 880 }}>
            <Pastille texte="Toutes les fonctions" debut={t(1.75)} />
            <Pastille texte="Sans publicité" debut={t(2)} />
            <Pastille texte="Sans achat intégré" debut={t(2.25)} />
          </div>
          <Objet nom="monstera" taille={640} x={430} y={1080 + (1 - pot) * 700} style={{ transform: `rotate(${(1 - pot) * 20}deg)` }} />
        </AbsoluteFill>
      </Fond>
    </Entree>
  );
};

// --- 8. La fin ---------------------------------------------------------------------
// Le pot revient, cligne de l'œil sur l'accord final, et l'annonce se pose.
export const SceneFin: React.FC = () => {
  const sous = useRessort(t(1.2), 200, 16);
  const dispo = useRessort(t(2), 220, 13);
  return (
    <Entree type="disque" x={300} y={520}>
      <Fond couleur={C.sauge}>
        <Pot taille={560} x={540} y={740} arrivee={0} clin={t(4)} />
        <Lettres texte="Auxine" debut={6} taille={190} couleur={C.blanc} y={1030} />
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
      </Fond>
    </Entree>
  );
};
