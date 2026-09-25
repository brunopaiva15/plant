// La grille du montage, celle de la musique : chaque scène commence sur une
// mesure, chaque geste tombe sur un temps. Le tempo et le premier temps du
// morceau sont mesurés par musique.py, qui écrit musique.json.
import musique from './musique.json';

export const FPS = 30;
export const BPM: number = musique.bpm;
/** Un temps, en images — pas forcément entier : 13,85 images à 130 BPM. */
export const TEMPS = (FPS * 60) / BPM;
export const MESURE = 4 * TEMPS;
/** [n] temps, arrondis à l'image. */
export const t = (n: number) => Math.round(n * TEMPS);
export const mesure = (m: number, temps = 0) => t(m * 4 + temps);

export const DUREE = mesure(13);

// Où commence chaque scène, en mesures.
export const SCENES = {
  photos: mesure(0), // les photos, une par temps, et « Le carnet de vos plantes. »
  pot: mesure(2), // le pot de l'icône, son clin d'œil, « Auxine »
  iris: mesure(3), // « Quelle est cette plante ? »
  soins: mesure(5), // « Chaque matin, les soins du jour. »
  diagnostic: mesure(7), // « Un diagnostic sur photo. »
  collection: mesure(8), // « Toutes vos plantes, au même endroit. »
  prix: mesure(9), // « 0,99 € »
  fin: mesure(10), // « Auxine » et « Disponible sur l'App Store. »
};

// Les zones que TikTok recouvre : on n'y pose pas de texte.
export const MARGE = { haut: 170, bas: 420, gauche: 80, droite: 140 };
