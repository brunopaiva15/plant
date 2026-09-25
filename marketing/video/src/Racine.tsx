import React from 'react';
import { AbsoluteFill, Composition } from 'remotion';
import { CameraMotionBlur } from '@remotion/motion-blur';
import { Film } from './Film';
import { DUREE, FPS } from './temps';

// L'image seule : le son est posé ensuite par ffmpeg (rendu.sh), calé à
// l'image près. Le flou de bougé mélange 6 sous-images par image, avec un
// obturateur à 180°, comme une caméra.
export const Sortie: React.FC<{ flou: boolean }> = ({ flou }) => (
  <AbsoluteFill>
    {flou ? (
      <CameraMotionBlur shutterAngle={180} samples={6}>
        <Film />
      </CameraMotionBlur>
    ) : (
      <Film />
    )}
  </AbsoluteFill>
);

export const Racine: React.FC = () => (
  <Composition id="Sortie" component={Sortie} durationInFrames={DUREE} fps={FPS} width={1080} height={1920} defaultProps={{ flou: true }} />
);
