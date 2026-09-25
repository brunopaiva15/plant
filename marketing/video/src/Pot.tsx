import React from 'react';
import { Img, staticFile, useCurrentFrame } from 'remotion';
import { geometrie, useRessort } from './outils';

/**
 * Le pot de l'icône, celui de l'ouverture de l'app : il se pose d'un rebond
 * à [arrivee], puis ferme l'œil droit à [clin] — les trois images de
 * l'ouverture (assets/splash/clin_*.webp), l'œil fermé tenu cinq images.
 */
export const Pot: React.FC<{ taille: number; x: number; y: number; arrivee: number; clin?: number }> = ({
  taille,
  x,
  y,
  arrivee,
  clin,
}) => {
  const frame = useCurrentFrame();
  const s = useRessort(arrivee, 200, 11);
  const o = geometrie.oeil;
  const k = taille / o.image;

  // Le clin d'œil, pas à pas, et le pot qui s'écrase un peu en fermant l'œil.
  let image: string | null = null;
  let ecrase = 0;
  if (clin !== undefined) {
    const d = frame - clin;
    const pas: [number, string | null][] = [
      [0, 'clin_50'], [1, 'clin_85'], [2, 'clin_100'], [7, 'clin_85'], [8, 'clin_50'], [9, null],
    ];
    for (const [debut, nom] of pas) if (d >= debut) image = nom;
    if (d < 0) image = null;
    ecrase = d >= 0 && d < 10 ? Math.sin((d / 10) * Math.PI) * 0.06 : 0;
  }

  return (
    <div
      style={{
        position: 'absolute',
        left: x - taille / 2,
        top: y - taille / 2,
        width: taille,
        height: taille,
        opacity: Math.min(1, s * 3),
        transform: `translateY(${(1 - s) * -260}px) scale(${(0.6 + 0.4 * s) * (1 + ecrase)}, ${(0.6 + 0.4 * s) * (1 - ecrase)})`,
        transformOrigin: '50% 92%',
      }}
    >
      <Img src={staticFile('logo.webp')} style={{ width: '100%', height: '100%' }} />
      {image && (
        <Img
          src={staticFile(`${image}.webp`)}
          style={{ position: 'absolute', left: o.x * k, top: o.y * k, width: o.cote * k, height: o.cote * k }}
        />
      )}
    </div>
  );
};
