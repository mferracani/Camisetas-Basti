// Camisetas — data layer
// Países, equipos, camisetas (titular + suplente) con colores y patrones.
// Patrón visual: 'stripes-v' (rayas verticales), 'stripes-h' (horizontales),
// 'sash' (banda diagonal), 'solid', 'split-v', 'hoops' (rayas horizontales gruesas)
// Cada equipo: { id, name, country, colors: [home1,home2,home3?], pattern, away: {...} }
// Crest: 'shape' (round/shield/diamond/banner), 'initials' o 'icon', 'colors'

const COUNTRIES = [
  { id: 'arg', name: 'ARGENTINA', flag: ['#75AADB', '#FFFFFF', '#75AADB'], emoji: '🇦🇷', sun: true },
  { id: 'eng', name: 'INGLATERRA', flag: 'cross-eng', emoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿' },
  { id: 'esp', name: 'ESPAÑA', flag: ['#AA151B', '#F1BF00', '#F1BF00', '#AA151B'], emoji: '🇪🇸', stripes: [1,2,1] },
  { id: 'ita', name: 'ITALIA', flag: 'vertical-3', flagColors: ['#008C45', '#F4F5F0', '#CD212A'], emoji: '🇮🇹' },
  { id: 'fra', name: 'FRANCIA', flag: 'vertical-3', flagColors: ['#0055A4', '#FFFFFF', '#EF4135'], emoji: '🇫🇷' },
  { id: 'ger', name: 'ALEMANIA', flag: ['#000000', '#DD0000', '#FFCE00'], emoji: '🇩🇪' },
];

const TEAMS = {
  arg: [
    { id: 'boca', name: 'BOCA JUNIORS', short: 'BOCA', home: { pattern: 'sash-h', c: ['#0A2A6C', '#FFD700'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0A2A6C'] }, crest: { shape: 'shield', text: 'CABJ', colors: ['#0A2A6C', '#FFD700'] } },
    { id: 'river', name: 'RIVER PLATE', short: 'RIVER', home: { pattern: 'sash-d', c: ['#FFFFFF', '#E2272F'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#E2272F'] }, crest: { shape: 'shield', text: 'CARP', colors: ['#E2272F', '#FFFFFF'] } },
    { id: 'racing', name: 'RACING CLUB', short: 'RACING', home: { pattern: 'stripes-v', c: ['#74ACDF', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#74ACDF'] }, crest: { shape: 'round', text: 'RC', colors: ['#74ACDF', '#FFFFFF'] } },
    { id: 'inde', name: 'INDEPENDIENTE', short: 'INDE', home: { pattern: 'solid', c: ['#C8102E', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#C8102E'] }, crest: { shape: 'diamond', text: 'CAI', colors: ['#C8102E', '#FFFFFF'] } },
    { id: 'sanlo', name: 'SAN LORENZO', short: 'SAN LO.', home: { pattern: 'stripes-v', c: ['#0A2A6C', '#C8102E'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0A2A6C'] }, crest: { shape: 'round', text: 'SL', colors: ['#0A2A6C', '#C8102E'] } },
    { id: 'velez', name: 'VÉLEZ', short: 'VÉLEZ', home: { pattern: 'sash-v', c: ['#FFFFFF', '#0A2A6C'] }, away: { pattern: 'solid', c: ['#0A2A6C', '#FFFFFF'] }, crest: { shape: 'shield', text: 'V', colors: ['#0A2A6C', '#FFFFFF'] } },
    { id: 'estu', name: 'ESTUDIANTES', short: 'ESTU.', home: { pattern: 'stripes-v', c: ['#FFFFFF', '#E2272F'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#E2272F'] }, crest: { shape: 'shield', text: 'EDLP', colors: ['#E2272F', '#FFFFFF'] } },
    { id: 'rosa', name: 'ROSARIO CENTRAL', short: 'CENTRAL', home: { pattern: 'stripes-v', c: ['#005EB8', '#FFE600'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#005EB8'] }, crest: { shape: 'shield', text: 'RC', colors: ['#005EB8', '#FFE600'] } },
    { id: 'newells', name: "NEWELL'S", short: 'NOB', home: { pattern: 'split-v', c: ['#E2272F', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#E2272F'] }, crest: { shape: 'shield', text: 'NOB', colors: ['#E2272F', '#1A1A1A'] } },
    { id: 'hura', name: 'HURACÁN', short: 'HURA.', home: { pattern: 'sash-h-thin', c: ['#FFFFFF', '#E2272F'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#E2272F'] }, crest: { shape: 'round', text: 'H', colors: ['#E2272F', '#FFFFFF'], icon: 'balloon' } },
  ],
  eng: [
    { id: 'mci', name: 'MANCHESTER CITY', short: 'MAN CITY', home: { pattern: 'solid', c: ['#6CABDD', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#0A2A6C', '#FFFFFF'] }, crest: { shape: 'round', text: 'MCFC', colors: ['#6CABDD', '#FFFFFF'] } },
    { id: 'mun', name: 'MANCHESTER UNITED', short: 'MAN UTD', home: { pattern: 'solid', c: ['#DA291C', '#FFE600'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#DA291C'] }, crest: { shape: 'shield', text: 'MUFC', colors: ['#DA291C', '#FFE600'] } },
    { id: 'liv', name: 'LIVERPOOL', short: 'LIV', home: { pattern: 'solid', c: ['#C8102E', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#C8102E'] }, crest: { shape: 'shield', text: 'LFC', colors: ['#C8102E', '#FFE600'] } },
    { id: 'ars', name: 'ARSENAL', short: 'ARS', home: { pattern: 'sleeves-w', c: ['#EF0107', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFE600', '#0A2A6C'] }, crest: { shape: 'shield', text: 'AFC', colors: ['#EF0107', '#FFE600'] } },
    { id: 'che', name: 'CHELSEA', short: 'CHE', home: { pattern: 'solid', c: ['#034694', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#034694'] }, crest: { shape: 'round', text: 'CFC', colors: ['#034694', '#FFE600'] } },
    { id: 'tot', name: 'TOTTENHAM', short: 'TOT', home: { pattern: 'solid', c: ['#FFFFFF', '#0A2A6C'] }, away: { pattern: 'solid', c: ['#0A2A6C', '#FFFFFF'] }, crest: { shape: 'shield', text: 'THFC', colors: ['#0A2A6C', '#FFFFFF'] } },
    { id: 'new', name: 'NEWCASTLE', short: 'NEW', home: { pattern: 'stripes-v', c: ['#1A1A1A', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#7FE3D9', '#1A1A1A'] }, crest: { shape: 'shield', text: 'NUFC', colors: ['#1A1A1A', '#FFFFFF'] } },
    { id: 'avl', name: 'ASTON VILLA', short: 'VILLA', home: { pattern: 'split-v-blue-claret', c: ['#7A003C', '#86C5FF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#7A003C'] }, crest: { shape: 'shield', text: 'AVFC', colors: ['#7A003C', '#86C5FF'] } },
    { id: 'whu', name: 'WEST HAM', short: 'WEST H.', home: { pattern: 'solid', c: ['#7A003C', '#1BB1E7'] }, away: { pattern: 'solid', c: ['#1BB1E7', '#7A003C'] }, crest: { shape: 'shield', text: 'WHU', colors: ['#7A003C', '#1BB1E7'] } },
    { id: 'eve', name: 'EVERTON', short: 'EVE', home: { pattern: 'solid', c: ['#003399', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#003399'] }, crest: { shape: 'shield', text: 'EFC', colors: ['#003399', '#FFFFFF'] } },
  ],
  esp: [
    { id: 'rma', name: 'REAL MADRID', short: 'REAL M.', home: { pattern: 'solid', c: ['#FFFFFF', '#FEBE10'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#FEBE10'] }, crest: { shape: 'round', text: 'RM', colors: ['#FEBE10', '#00529F'] } },
    { id: 'fcb', name: 'BARCELONA', short: 'BARÇA', home: { pattern: 'stripes-v', c: ['#A50044', '#004D98'] }, away: { pattern: 'solid', c: ['#FFE600', '#A50044'] }, crest: { shape: 'shield', text: 'FCB', colors: ['#A50044', '#004D98'] } },
    { id: 'atm', name: 'ATLÉTICO MADRID', short: 'ATLÉTI', home: { pattern: 'stripes-v', c: ['#CB3524', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#0A2A6C', '#FFFFFF'] }, crest: { shape: 'shield', text: 'ATM', colors: ['#CB3524', '#FFFFFF'] } },
    { id: 'ath', name: 'ATHLETIC CLUB', short: 'ATH.', home: { pattern: 'stripes-v', c: ['#EE2523', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#EE2523'] }, crest: { shape: 'shield', text: 'AC', colors: ['#EE2523', '#FFFFFF'] } },
    { id: 'rso', name: 'REAL SOCIEDAD', short: 'REAL S.', home: { pattern: 'stripes-v', c: ['#0067B1', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0067B1'] }, crest: { shape: 'shield', text: 'RS', colors: ['#0067B1', '#FFFFFF'] } },
    { id: 'sev', name: 'SEVILLA', short: 'SEVILLA', home: { pattern: 'solid', c: ['#FFFFFF', '#D9001A'] }, away: { pattern: 'solid', c: ['#D9001A', '#FFFFFF'] }, crest: { shape: 'shield', text: 'SFC', colors: ['#D9001A', '#FFFFFF'] } },
    { id: 'val', name: 'VALENCIA', short: 'VAL.', home: { pattern: 'solid', c: ['#FFFFFF', '#F18E00'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#F18E00'] }, crest: { shape: 'shield', text: 'VCF', colors: ['#F18E00', '#1A1A1A'], icon: 'bat' } },
    { id: 'vil', name: 'VILLARREAL', short: 'VILL.', home: { pattern: 'solid', c: ['#FFE600', '#005EB8'] }, away: { pattern: 'solid', c: ['#005EB8', '#FFE600'] }, crest: { shape: 'shield', text: 'VCF', colors: ['#FFE600', '#005EB8'] } },
    { id: 'bet', name: 'BETIS', short: 'BETIS', home: { pattern: 'stripes-v', c: ['#0BB363', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0BB363'] }, crest: { shape: 'shield', text: 'RB', colors: ['#0BB363', '#FFFFFF'] } },
    { id: 'gir', name: 'GIRONA', short: 'GIRONA', home: { pattern: 'stripes-v', c: ['#CB3524', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#FEBE10'] }, crest: { shape: 'shield', text: 'GFC', colors: ['#CB3524', '#FFFFFF'] } },
  ],
  ita: [
    { id: 'juv', name: 'JUVENTUS', short: 'JUVE', home: { pattern: 'stripes-v', c: ['#1A1A1A', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#1A1A1A'] }, crest: { shape: 'shield', text: 'J', colors: ['#1A1A1A', '#FFFFFF'] } },
    { id: 'int', name: 'INTER', short: 'INTER', home: { pattern: 'stripes-v', c: ['#0A2A6C', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0A2A6C'] }, crest: { shape: 'round', text: 'INT', colors: ['#0A2A6C', '#1A1A1A'] } },
    { id: 'mil', name: 'MILAN', short: 'MILAN', home: { pattern: 'stripes-v', c: ['#C8102E', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#C8102E'] }, crest: { shape: 'shield', text: 'AC', colors: ['#C8102E', '#1A1A1A'] } },
    { id: 'nap', name: 'NAPOLI', short: 'NAPOLI', home: { pattern: 'solid', c: ['#12A0D7', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#12A0D7'] }, crest: { shape: 'round', text: 'N', colors: ['#12A0D7', '#FFFFFF'] } },
    { id: 'rom', name: 'ROMA', short: 'ROMA', home: { pattern: 'solid', c: ['#8E1F2F', '#F2A93B'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#8E1F2F'] }, crest: { shape: 'shield', text: 'ASR', colors: ['#8E1F2F', '#F2A93B'] } },
    { id: 'laz', name: 'LAZIO', short: 'LAZIO', home: { pattern: 'solid', c: ['#87CEEB', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#87CEEB'] }, crest: { shape: 'round', text: 'SSL', colors: ['#87CEEB', '#FFFFFF'] } },
    { id: 'ata', name: 'ATALANTA', short: 'ATA.', home: { pattern: 'stripes-v', c: ['#1A1A1A', '#005EB8'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#005EB8'] }, crest: { shape: 'round', text: 'A', colors: ['#005EB8', '#1A1A1A'] } },
    { id: 'fio', name: 'FIORENTINA', short: 'FIO.', home: { pattern: 'solid', c: ['#5B2D88', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#5B2D88'] }, crest: { shape: 'diamond', text: 'F', colors: ['#5B2D88', '#FFFFFF'] } },
    { id: 'tor', name: 'TORINO', short: 'TORINO', home: { pattern: 'solid', c: ['#8E1F2F', '#FFE600'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#8E1F2F'] }, crest: { shape: 'shield', text: 'T', colors: ['#8E1F2F', '#FFE600'] } },
    { id: 'bol', name: 'BOLOGNA', short: 'BOLO.', home: { pattern: 'stripes-v', c: ['#8E1F2F', '#0A2A6C'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#8E1F2F'] }, crest: { shape: 'shield', text: 'BFC', colors: ['#8E1F2F', '#0A2A6C'] } },
  ],
  fra: [
    { id: 'psg', name: 'PSG', short: 'PSG', home: { pattern: 'sash-v-fat', c: ['#0A2A6C', '#C8102E'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#0A2A6C'] }, crest: { shape: 'round', text: 'PSG', colors: ['#0A2A6C', '#C8102E'] } },
    { id: 'mar', name: 'MARSEILLE', short: 'OM', home: { pattern: 'solid', c: ['#FFFFFF', '#2FAEE0'] }, away: { pattern: 'solid', c: ['#2FAEE0', '#FFFFFF'] }, crest: { shape: 'shield', text: 'OM', colors: ['#2FAEE0', '#FFFFFF'] } },
    { id: 'lyo', name: 'LYON', short: 'OL', home: { pattern: 'solid', c: ['#FFFFFF', '#C8102E'] }, away: { pattern: 'solid', c: ['#0A2A6C', '#FFFFFF'] }, crest: { shape: 'shield', text: 'OL', colors: ['#C8102E', '#0A2A6C'] } },
    { id: 'mon', name: 'MONACO', short: 'ASM', home: { pattern: 'split-d', c: ['#E2272F', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#E2272F'] }, crest: { shape: 'diamond', text: 'ASM', colors: ['#E2272F', '#FFFFFF'] } },
    { id: 'lil', name: 'LILLE', short: 'LOSC', home: { pattern: 'solid', c: ['#E2272F', '#0A2A6C'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#E2272F'] }, crest: { shape: 'shield', text: 'L', colors: ['#E2272F', '#0A2A6C'] } },
    { id: 'ren', name: 'RENNES', short: 'SRFC', home: { pattern: 'split-v', c: ['#E2272F', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#E2272F'] }, crest: { shape: 'shield', text: 'SR', colors: ['#E2272F', '#1A1A1A'] } },
    { id: 'len', name: 'LENS', short: 'RCL', home: { pattern: 'stripes-v', c: ['#E2272F', '#FFE600'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#FFE600'] }, crest: { shape: 'shield', text: 'RCL', colors: ['#E2272F', '#FFE600'] } },
    { id: 'nic', name: 'NICE', short: 'OGCN', home: { pattern: 'solid', c: ['#1A1A1A', '#E2272F'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#1A1A1A'] }, crest: { shape: 'round', text: 'OGCN', colors: ['#E2272F', '#1A1A1A'] } },
    { id: 'nan', name: 'NANTES', short: 'FCN', home: { pattern: 'solid', c: ['#FFE600', '#0BB363'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#FFE600'] }, crest: { shape: 'shield', text: 'FCN', colors: ['#FFE600', '#0BB363'] } },
    { id: 'str', name: 'STRASBOURG', short: 'RCSA', home: { pattern: 'solid', c: ['#005EB8', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#005EB8'] }, crest: { shape: 'shield', text: 'RCS', colors: ['#005EB8', '#FFFFFF'] } },
  ],
  ger: [
    { id: 'bay', name: 'BAYERN MUNICH', short: 'BAYERN', home: { pattern: 'solid', c: ['#DC052D', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#DC052D'] }, crest: { shape: 'round', text: 'FCB', colors: ['#DC052D', '#0066B2'] } },
    { id: 'bvb', name: 'DORTMUND', short: 'BVB', home: { pattern: 'solid', c: ['#FDE100', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#FDE100'] }, crest: { shape: 'round', text: 'BVB', colors: ['#FDE100', '#1A1A1A'] } },
    { id: 'lev', name: 'BAYER LEVERKUSEN', short: 'B04', home: { pattern: 'solid', c: ['#E32219', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#E32219'] }, crest: { shape: 'shield', text: 'B04', colors: ['#E32219', '#1A1A1A'] } },
    { id: 'rbl', name: 'RB LEIPZIG', short: 'RBL', home: { pattern: 'solid', c: ['#FFFFFF', '#DD0741'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#DD0741'] }, crest: { shape: 'shield', text: 'RBL', colors: ['#DD0741', '#FDE100'] } },
    { id: 'stu', name: 'STUTTGART', short: 'VFB', home: { pattern: 'sash-h-thick', c: ['#FFFFFF', '#E32219'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#E32219'] }, crest: { shape: 'shield', text: 'VFB', colors: ['#E32219', '#FFFFFF'] } },
    { id: 'sge', name: 'EINTRACHT FRANKFURT', short: 'SGE', home: { pattern: 'solid', c: ['#1A1A1A', '#E32219'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#1A1A1A'] }, crest: { shape: 'round', text: 'SGE', colors: ['#1A1A1A', '#E32219'] } },
    { id: 'bmg', name: 'MÖNCHENGLADBACH', short: 'BMG', home: { pattern: 'solid', c: ['#FFFFFF', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#1A1A1A', '#0BB363'] }, crest: { shape: 'diamond', text: 'BMG', colors: ['#0BB363', '#1A1A1A'] } },
    { id: 'wob', name: 'WOLFSBURG', short: 'WOB', home: { pattern: 'solid', c: ['#65B32E', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#65B32E'] }, crest: { shape: 'shield', text: 'WOB', colors: ['#65B32E', '#FFFFFF'] } },
    { id: 'scf', name: 'FREIBURG', short: 'SCF', home: { pattern: 'solid', c: ['#E32219', '#1A1A1A'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#E32219'] }, crest: { shape: 'round', text: 'SCF', colors: ['#E32219', '#FFFFFF'] } },
    { id: 'wer', name: 'WERDER BREMEN', short: 'WER', home: { pattern: 'solid', c: ['#1D9053', '#FFFFFF'] }, away: { pattern: 'solid', c: ['#FFFFFF', '#1D9053'] }, crest: { shape: 'diamond', text: 'SVW', colors: ['#1D9053', '#FFFFFF'] } },
  ],
};

// Track discovered state for the album. 0=locked, 1=partial, 2=complete.
// Seed some example progress so the screens have something to show.
const SEED_PROGRESS = {
  'arg.boca.home': 2, 'arg.boca.away': 2,
  'arg.river.home': 2, 'arg.river.away': 1,
  'arg.racing.home': 2, 'arg.racing.away': 2,
  'arg.inde.home': 1,
  'arg.sanlo.home': 2, 'arg.sanlo.away': 0,
  'arg.velez.home': 0,
  'esp.fcb.home': 2, 'esp.fcb.away': 1,
  'esp.rma.home': 2, 'esp.rma.away': 2,
  'esp.atm.home': 1,
  'eng.mci.home': 2, 'eng.liv.home': 2, 'eng.ars.home': 1,
  'ita.juv.home': 2, 'ita.int.home': 2, 'ita.mil.home': 1,
  'fra.psg.home': 2, 'fra.mar.home': 1,
  'ger.bay.home': 2, 'ger.bvb.home': 2, 'ger.lev.home': 1,
};

window.CAMI_DATA = { COUNTRIES, TEAMS, SEED_PROGRESS };
