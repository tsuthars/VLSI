package GridCell;
use 5.014;
use warnings;
use Class::Struct;

struct GridCell => { # Definition of Grid Cell
  Cost      => '$',  # Cost of Cell (a small number)
  Pred      => '$',  # Predecessor Tag (N/S/E/W/U/D)
  Reached   => '$'   # 1 bit Boolean true/false
};
1;
