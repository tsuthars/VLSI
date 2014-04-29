package WaveCell;
use 5.014;
use warnings;
use Class::Struct;

struct WaveCell => { # Definition of Cell in Wavefront
  x         => '$',  # x Coordinate of cell in grid
  y         => '$',  # y Coordinate of cell in grid
  Layer     => '$',  # Which grid is it in (1,2,3...etc.)
  Pathcost  => '$',  # Sum of all costs upto current cell
  Pred      => '$'   # Predecessor tag (N/S/E/W/U/D) is also in GridCell
};
1;
