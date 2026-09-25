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

// Le déroulé, temps par temps, est dans PARTITION.md et src/Film.tsx.

// Les zones que TikTok recouvre : on n'y pose pas de texte.
export const MARGE = { haut: 170, bas: 420, gauche: 80, droite: 140 };
