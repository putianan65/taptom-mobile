import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One icon family for the whole app (Phosphor, regular weight), referenced by
/// meaning rather than by glyph name so swapping a glyph is a one-line change.
abstract final class AppIcons {
  // Navigation
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeActive = PhosphorIconsFill.house;
  static const IconData map = PhosphorIconsRegular.mapTrifold;
  static const IconData mapActive = PhosphorIconsFill.mapTrifold;
  static const IconData records = PhosphorIconsRegular.notebook;
  static const IconData recordsActive = PhosphorIconsFill.notebook;
  static const IconData account = PhosphorIconsRegular.userCircle;
  static const IconData accountActive = PhosphorIconsFill.userCircle;
  static const IconData members = PhosphorIconsRegular.users;
  static const IconData membersActive = PhosphorIconsFill.users;
  static const IconData officers = PhosphorIconsRegular.identificationCard;
  static const IconData officersActive = PhosphorIconsFill.identificationCard;
  static const IconData menu = PhosphorIconsRegular.squaresFour;
  static const IconData menuActive = PhosphorIconsFill.squaresFour;
  static const IconData overview = PhosphorIconsRegular.chartLineUp;
  static const IconData overviewActive = PhosphorIconsFill.chartLineUp;

  // Agriculture
  static const IconData plant = PhosphorIconsRegular.plant;
  static const IconData leaf = PhosphorIconsRegular.leaf;
  static const IconData plot = PhosphorIconsRegular.polygon;
  static const IconData harvest = PhosphorIconsRegular.basket;
  static const IconData postHarvest = PhosphorIconsRegular.package;
  static const IconData inputs = PhosphorIconsRegular.flask;
  static const IconData fieldWork = PhosphorIconsRegular.shovel;
  static const IconData water = PhosphorIconsRegular.drop;
  static const IconData safety = PhosphorIconsRegular.firstAid;
  static const IconData training = PhosphorIconsRegular.chalkboardTeacher;
  static const IconData lot = PhosphorIconsRegular.barcode;
  static const IconData weight = PhosphorIconsRegular.scales;
  static const IconData area = PhosphorIconsRegular.ruler;
  static const IconData sun = PhosphorIconsRegular.sun;
  static const IconData tree = PhosphorIconsRegular.tree;
  static const IconData truck = PhosphorIconsRegular.truck;

  // Documents and compliance
  static const IconData gap = PhosphorIconsRegular.sealCheck;
  static const IconData certificate = PhosphorIconsRegular.certificate;
  static const IconData checklist = PhosphorIconsRegular.listChecks;
  static const IconData clipboard = PhosphorIconsRegular.clipboardText;
  static const IconData document = PhosphorIconsRegular.fileText;
  static const IconData pdf = PhosphorIconsRegular.filePdf;
  static const IconData history = PhosphorIconsRegular.clockCounterClockwise;
  static const IconData audit = PhosphorIconsRegular.detective;
  static const IconData privacy = PhosphorIconsRegular.shieldCheck;
  static const IconData terms = PhosphorIconsRegular.scroll;

  // Location
  static const IconData pin = PhosphorIconsRegular.mapPin;
  static const IconData pinLine = PhosphorIconsRegular.mapPinLine;
  static const IconData locate = PhosphorIconsRegular.crosshair;
  static const IconData layers = PhosphorIconsRegular.stack;
  static const IconData compass = PhosphorIconsRegular.compass;

  // Traceability
  static const IconData qr = PhosphorIconsRegular.qrCode;
  static const IconData scan = PhosphorIconsRegular.scan;

  // People and roles
  static const IconData user = PhosphorIconsRegular.user;
  static const IconData users = PhosphorIconsRegular.users;
  static const IconData userAdd = PhosphorIconsRegular.userPlus;
  static const IconData userSwitch = PhosphorIconsRegular.userSwitch;
  static const IconData officer = PhosphorIconsRegular.identificationBadge;
  static const IconData superAdmin = PhosphorIconsRegular.crown;
  static const IconData phone = PhosphorIconsRegular.phone;
  static const IconData birthday = PhosphorIconsRegular.calendarBlank;
  static const IconData calendar = PhosphorIconsRegular.calendar;
  static const IconData building = PhosphorIconsRegular.buildings;

  // Communication
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData bellActive = PhosphorIconsFill.bell;
  static const IconData bellOff = PhosphorIconsRegular.bellSlash;
  static const IconData chat = PhosphorIconsRegular.chatCircleText;
  static const IconData chats = PhosphorIconsRegular.chatsCircle;
  static const IconData mail = PhosphorIconsRegular.envelopeSimple;
  static const IconData send = PhosphorIconsRegular.paperPlaneTilt;
  static const IconData inbox = PhosphorIconsRegular.tray;
  static const IconData support = PhosphorIconsRegular.lifebuoy;
  static const IconData mic = PhosphorIconsRegular.microphone;
  static const IconData star = PhosphorIconsRegular.star;
  static const IconData starFill = PhosphorIconsFill.star;

  // Security
  static const IconData lock = PhosphorIconsRegular.lockKey;
  static const IconData shield = PhosphorIconsRegular.shieldCheck;
  static const IconData fingerprint = PhosphorIconsRegular.fingerprint;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData eyeOff = PhosphorIconsRegular.eyeSlash;
  static const IconData backspace = PhosphorIconsRegular.backspace;

  // Actions
  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData check = PhosphorIconsRegular.check;
  static const IconData checkCircle = PhosphorIconsRegular.checkCircle;
  static const IconData checkCircleFill = PhosphorIconsFill.checkCircle;
  static const IconData xCircle = PhosphorIconsRegular.xCircle;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter = PhosphorIconsRegular.funnelSimple;
  static const IconData sort = PhosphorIconsRegular.sortAscending;
  static const IconData refresh = PhosphorIconsRegular.arrowsClockwise;
  static const IconData undo = PhosphorIconsRegular.arrowUUpLeft;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData gallery = PhosphorIconsRegular.images;
  static const IconData download = PhosphorIconsRegular.downloadSimple;
  static const IconData share = PhosphorIconsRegular.shareNetwork;
  static const IconData print = PhosphorIconsRegular.printer;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData external = PhosphorIconsRegular.arrowSquareOut;
  static const IconData more = PhosphorIconsRegular.dotsThreeVertical;
  static const IconData moreHorizontal = PhosphorIconsRegular.dotsThree;
  static const IconData save = PhosphorIconsRegular.floppyDisk;
  static const IconData draft = PhosphorIconsRegular.notePencil;
  static const IconData logout = PhosphorIconsRegular.signOut;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData sliders = PhosphorIconsRegular.slidersHorizontal;
  static const IconData broom = PhosphorIconsRegular.broom;
  static const IconData attach = PhosphorIconsRegular.paperclip;

  // Arrows
  static const IconData back = PhosphorIconsRegular.arrowLeft;
  static const IconData forward = PhosphorIconsRegular.arrowRight;
  static const IconData chevronRight = PhosphorIconsRegular.caretRight;
  static const IconData chevronLeft = PhosphorIconsRegular.caretLeft;
  static const IconData chevronDown = PhosphorIconsRegular.caretDown;
  static const IconData chevronUp = PhosphorIconsRegular.caretUp;
  static const IconData arrowUpRight = PhosphorIconsRegular.arrowUpRight;

  // Status
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData warningCircle = PhosphorIconsRegular.warningCircle;
  static const IconData pending = PhosphorIconsRegular.hourglassMedium;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData offline = PhosphorIconsRegular.wifiSlash;
  static const IconData help = PhosphorIconsRegular.question;

  // Appearance
  static const IconData moon = PhosphorIconsRegular.moon;
  static const IconData sunDim = PhosphorIconsRegular.sunDim;
  static const IconData language = PhosphorIconsRegular.translate;
  static const IconData textSize = PhosphorIconsRegular.textAa;
  static const IconData chart = PhosphorIconsRegular.chartBar;
  static const IconData database = PhosphorIconsRegular.database;
  static const IconData sparkle = PhosphorIconsRegular.sparkle;
  static const IconData megaphone = PhosphorIconsRegular.megaphone;
  static const IconData barcode = PhosphorIconsRegular.barcode;
  static const IconData plantFill = PhosphorIconsFill.plant;
  static const IconData cloudArrowUp = PhosphorIconsRegular.cloudArrowUp;
  static const IconData listBullets = PhosphorIconsRegular.listBullets;
  static const IconData gridFour = PhosphorIconsRegular.gridFour;
  static const IconData pushPin = PhosphorIconsRegular.pushPin;
  static const IconData path = PhosphorIconsRegular.path;
  static const IconData calendarCheck = PhosphorIconsRegular.calendarCheck;
  static const IconData thermometer = PhosphorIconsRegular.thermometer;
  static const IconData handshake = PhosphorIconsRegular.handshake;
  static const IconData seal = PhosphorIconsRegular.seal;
  static const IconData note = PhosphorIconsRegular.note;
}
