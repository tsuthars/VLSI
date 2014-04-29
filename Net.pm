package Net;
use 5.014;
use warnings;
use Class::Struct;

struct Net => {      # Definition of a net
  NetID     => '$',  # Net ID
  LayerPin1 => '$',  # Layer on which Pin1 is located
  Xpin1     => '$',  # X coordinate of Pin1
  Ypin1     => '$',  # Y coordinate of Pin1
  LayerPin2 => '$',  # Layer on which Pin2 is located
  Xpin2     => '$',  # X coordinate of Pin2
  Ypin2     => '$'   # Y coordinate of Pin2
};
1;
