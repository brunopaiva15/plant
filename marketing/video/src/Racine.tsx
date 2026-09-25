import React from 'react';
import { AbsoluteFill, Audio, Composition, Sequence, interpolate, staticFile } from 'remotion';
import { DUREE, FPS, SCENES } from './temps';
import {
  SceneCollection,
  SceneDiagnostic,
  SceneFin,
  ScenePhotos,
  ScenePot,
  ScenePrix,
  SceneIris,
  SceneSoins,
} from './Scenes';

// Chaque scène déborde de 14 images sur la suivante, qui entre par-dessus :
// la précédente reste dessous le temps que la transition la couvre.
const DEBORD = 14;
const ordre: [keyof typeof SCENES, React.FC][] = [
  ['photos', ScenePhotos],
  ['pot', ScenePot],
  ['iris', SceneIris],
  ['soins', SceneSoins],
  ['diagnostic', SceneDiagnostic],
  ['collection', SceneCollection],
  ['prix', ScenePrix],
  ['fin', SceneFin],
];

export const Sortie: React.FC<{ musique: boolean }> = ({ musique }) => (
  <AbsoluteFill style={{ backgroundColor: '#FFE14D' }}>
    {ordre.map(([nom, Scene], i) => {
      const debut = SCENES[nom];
      const suivante = i + 1 < ordre.length ? SCENES[ordre[i + 1][0]] : DUREE;
      return (
        <Sequence key={nom} name={nom} from={debut} durationInFrames={suivante - debut + (i + 1 < ordre.length ? DEBORD : 0)}>
          <Scene />
        </Sequence>
      );
    })}
    {musique && (
      <Audio
        src={staticFile('musique.wav')}
        volume={(f) => interpolate(f, [DUREE - 20, DUREE], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })}
      />
    )}
  </AbsoluteFill>
);

export const Racine: React.FC = () => (
  <>
    <Composition id="Sortie" component={Sortie} durationInFrames={DUREE} fps={FPS} width={1080} height={1920} defaultProps={{ musique: true }} />
    <Composition id="SortieMuette" component={Sortie} durationInFrames={DUREE} fps={FPS} width={1080} height={1920} defaultProps={{ musique: false }} />
  </>
);
