// La grille du montage, celle de la musique (musique.py) : 120 BPM, 30
// images par seconde. Un temps dure 15 images, une mesure 60. Chaque scène
// commence sur une mesure, chaque geste tombe sur un temps.
export const FPS = 30;
export const TEMPS = 15;
export const MESURE = 4 * TEMPS;
export const mesure = (m: number, temps = 0) => m * MESURE + temps * TEMPS;

export const DUREE = mesure(12);

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
