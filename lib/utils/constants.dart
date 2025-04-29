// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

const ON_SEND = 0x11;
const OFF_SEND = 0x12;
const MODE_SEND = 0x13;
const UP_SEND = 0x14;
const DOWN_SEND = 0x15;

const FLOAT_SEND = 0x00;
const MSG_SEND = 0x05;
const MSG_RECV = 0x05;
const FILE_SEND = 0x06;
const PASSWORD_SEND = 0x07;
const PING = 0x30;

const FLOAT_RECV = 0x08;
const PASSWORD_VALID = 0x07;
const PASSWORD_INVALID = 0x09;

const MAX_LOG_LINES = 100;

const PACKET_SIZE = 8;

const List<Color> COLORS_PALETTE = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.grey,
];
