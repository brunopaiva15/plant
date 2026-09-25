import React from 'react';
import { AbsoluteFill, Audio, Composition, staticFile } from 'remotion';
import { Film } from './Film';
import { DUREE, FPS } from './temps';

export const Sortie: React.FC<{ musique: boolean }> = ({ musique }) => (
  <AbsoluteFill>
    <Film />
    {/* Le passage, déjà coupé sur ses temps et fondu par musique.py. */}
    {musique && <Audio src={staticFile('musique.wav')} />}
  </AbsoluteFill>
);

export const Racine: React.FC = () => (
  <>
    <Composition id="Sortie" component={Sortie} durationInFrames={DUREE} fps={FPS} width={1080} height={1920} defaultProps={{ musique: true }} />
    <Composition id="SortieMuette" component={Sortie} durationInFrames={DUREE} fps={FPS} width={1080} height={1920} defaultProps={{ musique: false }} />
  </>
);
