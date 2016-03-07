# Piece class defines a piece in general
class Piece
  attr_accessor :location, :board, :html_text
  attr_reader :color, :piece
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 1
    @possible_directions = [:north, :south, :east, :west,
                            :northeast, :northwest, :southeast, :southwest]
    @piece = ''
    @board = nil
  end

  def my_king
    return @board.black_king if @color == :black
    return @board.white_king if @color == :white
  end

  def eql?(other)
    (self.class == other.class) && (@color == other.piece_color)
  end

  def ==(other)
    self.eql?(other)
  end

  def move_to(row, col)
    move = [row, col]
    current_piece = @board.piece_at(location[0], location[1])
    return nil unless possible_moves.include?(move)
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    current_piece.location = [row, col]
  end

  def occupied_targets
    @board.occupied_targets
  end

  def enemies_of(piece)
    occupied_targets.map do |target|
      @board.piece_at(target[0], target[1])
    end.select { |target| target.enemy_of?(piece) }
  end

  # Calculates possible moves based on possible_directions and reach
  def possible_moves
    moves = []
    @reach.downto(-@reach) {|num| moves << num}
    moves = moves.repeated_permutation(2).to_a
    moves = apply_directions(moves)
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
    moves.delete_if { |move| checkable_move?(move[0], move[1]) }
  end

  def possible_moves_without_relatives
    moves = []
    @reach.downto(-@reach) {|num| moves << num}
    moves = moves.repeated_permutation(2).to_a
    moves = apply_directions(moves)
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
  end

  def apply_relative_pieces(moves)
    moves_to_delete = []
    moves.each do |target|
      moves_to_delete << target if (occupied_targets.include?(target)) && (not reachable_enemy?(target))
    end
    moves.each do |target|
      moves_to_delete.each do |to_delete|
        moves_to_delete << target if further_than?(to_delete, target, @location)
      end
    end
    moves.delete_if { |move| moves_to_delete.include?(move) }
  end

  def reachable_enemy?(target)
    return false if @board.piece_at(target[0], target[1]).nil?
    return false if @board.piece_at(target[0], target[1]).color == @color
    occupied_targets.each do |occ_target|
      return false if further_than?(occ_target, target, @location)
    end
    return false unless possible_moves_without_relatives.include?(target)
    true
  end

  def enemy_of?(other_piece)
    return false if other_piece.nil?
    @color != other_piece.color
  end

  # Discards moves that are not possible on an 8 by 8 board.
  def apply_board_limits(moves)
    moves.delete_if do |move|
      move[0] < 0 ||
      move[0] > 7 ||
      move[1] < 0 ||
      move[1] > 7
    end
  end

  # Applies location to possible moves
  def apply_location(moves)
    moves.delete([0,0])
    moves.map { |move| [(move[0] + @location[0]), (move[1] + @location[1])]}
  end

  # Filters possible moves with possible_directions
  def apply_directions(moves)
    moves.delete_if do |move|
      ((move[0] * -1) != move[1]) && (not cardinal_move?(move)) && (move[0] != move[1])
    end
    moves.delete_if { |move| northern_move?(move) } unless can_move_north?
    moves.delete_if { |move| southern_move?(move) } unless can_move_south?
    moves.delete_if { |move| eastern_move?(move) } unless can_move_east?
    moves.delete_if { |move| western_move?(move) } unless can_move_west?
    moves.delete_if { |move| northeastern_move?(move) } unless can_move_northeast?
    moves.delete_if { |move| northwestern_move?(move) } unless can_move_northwest?
    moves.delete_if { |move| southeastern_move?(move) } unless can_move_southeast?
    moves.delete_if { |move| southwestern_move?(move) } unless can_move_southwest?
    moves
  end

  def same_direction?(first_target, second_target, relation)
    return true if north_of?(first_target, relation) && north_of?(second_target, relation)
    return true if south_of?(first_target, relation) && south_of?(second_target, relation)
    return true if east_of?(first_target, relation) && east_of?(second_target, relation)
    return true if west_of?(first_target, relation) && west_of?(second_target, relation)
    return true if northeast_of?(first_target, relation) && northeast_of?(second_target, relation)
    return true if northwest_of?(first_target, relation) && northwest_of?(second_target, relation)
    return true if southeast_of?(first_target, relation) && southeast_of?(second_target, relation)
    return true if southwest_of?(first_target, relation) && southwest_of?(second_target, relation)
    false
  end

  def further_than?(first_target, second_target, relation)
    return false if not same_direction?(first_target, second_target, relation)
    return true if north_of?(first_target, relation) && (north_of?(second_target, first_target))
    return true if south_of?(first_target, relation) && (south_of?(second_target, first_target))
    return true if west_of?(first_target, relation) && (west_of?(second_target, first_target))
    return true if east_of?(first_target, relation) && (east_of?(second_target, first_target))
    return true if northeast_of?(first_target, relation) && (northeast_of?(second_target, first_target))
    return true if northwest_of?(first_target, relation) && (northwest_of?(second_target, first_target))
    return true if southeast_of?(first_target, relation) && (southeast_of?(second_target, first_target))
    return true if southwest_of?(first_target, relation) && (southwest_of?(second_target, first_target))
    false
  end

  def checkable_move?(row, col)
    move = [row, col]
    previous_loc = @location
    checkable = false
    current_piece = @board.piece_at(location[0], location[1])
    enemy_piece = @board.piece_at(row, col) unless @board.piece_at(row, col).nil?
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    current_piece.location = [row, col]
    checkable = my_king.check?
    current_piece.location = previous_loc
    @board.space_equals(current_piece.location[0], current_piece.location[1], current_piece)
    @board.space_equals(row, col, enemy_piece)
    checkable
  end

  def diagonal_of?(target, current)
    (target[0] - current[0]) == (target[1] - current[1]) ||
    (target[0] - current[0]) * -1 == (target[1] - current[1])
  end

  def north_of?(target, current)
    target[0] > current[0] && target[1] == current[1]
  end

  def south_of?(target, current)
    target[0] < current[0] && target[1] == current[1]
  end

  def east_of?(target, current)
    target[1] > current[1] && target[0] == current[0]
  end

  def west_of?(target, current)
    target[1] < current[1] && target[0] == current[0]
  end

  def northeast_of?(target, current)
    diagonal_of?(target, current) &&
    target[0] > current[0] && target[1] > current[1]
  end

  def northwest_of?(target, current)
    diagonal_of?(target, current) && target[0] > current[0] && target[1] < current[1]
  end

  def southeast_of?(target, current)
    diagonal_of?(target, current) && target[0] < current[0] && target[1] > current[1]
  end

  def southwest_of?(target, current)
    diagonal_of?(target, current) && target[0] < current[0] && target[1] < current[1]
  end

  def cardinal_move?(move)
    northern_move?(move) || southern_move?(move) || western_move?(move) || eastern_move?(move)
  end

  def northern_move?(move)
    move[0] >= 1 && move[1] == 0
  end

  def southern_move?(move)
    move[0] <= -1 && move[1] == 0
  end

  def eastern_move?(move)
    move[1] >= 1 && move[0] == 0
  end

  def western_move?(move)
    move[1] <= -1 && move[0] == 0
  end

  def northeastern_move?(move)
    move[0] >= 1 && move[1] >= 1
  end

  def northwestern_move?(move)
    move[0] >= 1 && move[1] <= -1
  end

  def southeastern_move?(move)
    move[0] <= -1 && move[1] >= 1
  end

  def southwestern_move?(move)
    move[0] <= -1 && move[1] <= -1
  end

  def can_move_north?
    @possible_directions.include?(:north)
  end

  def can_move_south?
    @possible_directions.include?(:south)
  end

  def can_move_east?
    @possible_directions.include?(:east)
  end

  def can_move_west?
    @possible_directions.include?(:east)
  end

  def can_move_northeast?
    @possible_directions.include?(:northeast)
  end

  def can_move_northwest?
    @possible_directions.include?(:northwest)
  end

  def can_move_southeast?
    @possible_directions.include?(:southeast)
  end

  def can_move_southwest?
    @possible_directions.include?(:southwest)
  end
end

# Pawn Class inherits Piece Class
class Pawn < Piece
  attr_accessor :row_loc, :col_loc, :board, :html_text
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 1
    @possible_directions = [:north]
    @piece = "\u265f"
    @board = nil
    @row_loc = @location[0]
    @col_loc = @location[1]
    @has_moved = false
  end

  def possible_moves
    moves = []
    if @color == :black
      two_in_front = @board.piece_at((@location[0] - 2), @location[1])
      northern_space = @board.piece_at((@row_loc - 1), @col_loc)
      northeastern_space = @board.piece_at((@row_loc - 1), (@col_loc - 1))
      northwestern_space = @board.piece_at((@row_loc - 1), (@col_loc + 1))
    else
      two_in_front = @board.piece_at((@row_loc + 2), @col_loc)
      northern_space = @board.piece_at((@row_loc + 1), @col_loc)
      northeastern_space = @board.piece_at((@row_loc + 1), (@col_loc + 1))
      northwestern_space = @board.piece_at((@row_loc + 1), (@col_loc - 1))
    end
    
    current_piece = @board.piece_at(@row_loc, @col_loc)
    if northern_space.nil? && @color == :white
      moves << [(@row_loc + 1), (@col_loc)]
    end
    if northern_space.nil? && @color == :black
      moves << [(@row_loc - 1), (@col_loc)]
    end
    if (!northeastern_space.nil?) && northeastern_space.enemy_of?(current_piece)
      moves << northeastern_space.location
    end
    if (!northwestern_space.nil?) && northwestern_space.enemy_of?(current_piece)
      moves << northwestern_space.location
    end
    if (!@has_moved) && (two_in_front).nil? && (@color == :black)
      moves << [(@row_loc - 2), (@col_loc)]
    end
    if (!@has_moved) && (two_in_front).nil? && (@color == :white)
      moves << [(@row_loc + 2), (@col_loc)]
    end
    moves
  end

  def move_to(row, col)
    move = [row, col]
    current_piece = @board.piece_at(location[0], location[1])
    return nil unless possible_moves.include?(move)
    @has_moved = true
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    current_piece.location = [row, col]
    current_piece.row_loc = row
    current_piece.col_loc = col
  end
end

# Knight Class inherits Piece Class
class Knight < Piece
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @piece = "\u265e"
    @board = nil
  end

# Knight's movements are different from other pieces
  def possible_moves
    moves = [[-1, 2], [1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1]]
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
  end

  def apply_relative_pieces(moves)
    moves.delete_if { |move| occupied_targets.include?(move) }
  end
end

# Bishop Class inherits Piece Class
class Bishop < Piece
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 7
    @possible_directions = [:northeast, :northwest,
                            :southeast, :southwest]
    @piece = "\u265d"
    @board = nil
  end
end

# Rook Class inherits Piece Class
class Rook < Piece
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 7
    @possible_directions = [:north, :south, :east, :west]
    @piece = "\u265c"
    @board = nil
  end
end

# Queen Class inherits Piece Class
class Queen < Piece
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 7
    @possible_directions = [:north, :south, :east, :west,
                            :northeast, :northwest, :southeast, :southwest]
    @piece = "\u265b"
    @board = nil
    @html_text = "&#9819"
  end
end

# King Class inherits Piece Class
class King < Piece
  attr_reader :board, :html_text
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 1
    @possible_directions = [:north, :south, :east, :west,
                            :northeast, :northwest, :southeast, :southwest]
    @piece = "\u265a"
    @board = nil
    @html_text = "&#9818"
  end

  def possible_moves
    moves = []
    @reach.downto(-@reach) {|num| moves << num}
    moves = moves.repeated_permutation(2).to_a
    moves = apply_directions(moves)
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
    moves.delete_if do |move|
      checkable_move?(move[0], move[1])
    end
  end

  def my_enemies
    me = @board.piece_at(@location[0], @location[1])
    enemies_of(me)
  end

  def check?
    my_enemies.each do |enemy|
      if enemy.possible_moves.include?(@location)
        return true
      end
    end
    false
  end

  def checkmate?
    return false if !check?
    possible_moves.each do |move|
      return false if !checkable_move?(move[0], move[1])
    end
    true
  end

  def move_to(row, col)
    move = [row, col]
    current_piece = @board.piece_at(location[0], location[1])
    return nil unless possible_moves.include?(move)
    return nil if checkable_move?(row, col)
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    current_piece.location = [row, col]
    current_piece.row_loc = row
    current_piece.col_loc = col
  end

  def checkable_move?(row, col)
    move = [row, col]
    previous_loc = @location
    checkable = false
    current_piece = @board.piece_at(location[0], location[1])
    enemy_piece = @board.piece_at(row, col) unless @board.piece_at(row, col).nil?
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    current_piece.location = [row, col]
    checkable = current_piece.check?
    current_piece.location = previous_loc
    @board.space_equals(current_piece.location[0], current_piece.location[1], current_piece)
    @board.space_equals(row, col, enemy_piece)
    checkable
  end
end
