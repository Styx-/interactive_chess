#require_relative "piece.rb"
#require_relative "board.rb"
class Game

  def initialize
    @board = Board.new
    set_board_pointer(@board)
  end

  def set_board_pointer(board)
    0.upto(7).each do |row|
      0.upto(7).each do |col|
        board.board[row][col].board = board if not board.board[row][col].nil?
      end
    end
  end

  def get_piece_text(col, row)
    return "" if @board.get_piece(col, row).nil?
    @board.get_piece(col, row).html_text
  end

  def get_piece_color(col, row)
    return "" if @board.get_piece(col, row).nil?
    @board.get_piece(col, row).color
  end

  def valid_move(current_col, current_row, target_col, target_row)
    @board.get_piece(current_col, current_row).possible_moves.include?(@board.convert_to_move(target_col, target_row))
  end

  def set_piece(current_col, current_row, target_col, target_row)
    piece = @board.get_piece(current_col, current_row)
    enemy_piece = nil
    enemy_piece = @board.get_piece(target_col, target_row) unless @board.get_piece(target_col, target_row).nil?
    @board.set_piece(piece, target_col, target_row)
    if piece.my_king.check?
      puts "piece is a #{piece.class} and it's location is #{piece.location}"
      previous_loc = @board.convert_to_move(current_col, current_row)
      target_loc = @board.convert_to_move(target_col, target_row)
      @board.space_equals(previous_loc[0], previous_loc[1], piece)
      @board.piece_at(previous_loc[0], previous_loc[1] ).location = previous_loc
      @board.space_equals(target_loc[0], target_loc[1], enemy_piece)
      @board.piece_at(target_loc[0], target_loc[1] ).location = target_loc unless @board.piece_at(target_loc[0], target_loc[1] ).nil?
    end
  end
end

#chess_game

#board = Board.new
#set_board_pointer(board)

#board.display_board

#board.board[5][3] = Rook.new([5, 3], :black)
#rook = board.piece_at(5, 3)
#rook.board = board

#board.board[4][3] = Rook.new([4, 3], :white)
#rook_two = board.piece_at(4, 3)
#rook_two.board = board

#board.board[3][3] = King.new([3, 3], :white)
#king = board.piece_at(3, 3)
#king.board = board

#board.space_equals(0, 4, nil)

#board.display_board

#puts rook_two.checkable_move?(5, 3)

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
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    @board.space_equals(row, col, current_piece)
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
    moves = moves.my_repeated_permutation.to_a
    moves = apply_directions(moves)
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
    moves << @location
    #moves.delete_if { |move| checkable_move?(move[0], move[1]) }
  end

  def possible_moves_without_relatives
    moves = []
    @reach.downto(-@reach) {|num| moves << num}
    moves = moves.my_repeated_permutation.to_a
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
    #moves.delete([0,0])
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
    moves << [0,0]
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
  attr_accessor :row_loc, :col_loc, :board, :html_text, :location
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
    @html_text = "&#9823"
  end

  def possible_moves
    puts "started pawn possible moves"
    moves = []
    if @color == :black
      two_in_front = @board.piece_at((@location[0] - 2), @location[1])
      northern_space = @board.piece_at((@row_loc - 1), @col_loc)
      northeastern_space = @board.piece_at((@row_loc - 1), (@col_loc - 1))
      northwestern_space = @board.piece_at((@row_loc - 1), (@col_loc + 1))
    else
      puts "started white branch, @location:#{@location}"
      two_in_front = @board.piece_at((@row_loc + 2), @col_loc)
      puts "finished two_in_front"
      northern_space = @board.piece_at((@row_loc + 1), @col_loc)
      puts "finished northern_space"
      northeastern_space = @board.piece_at((@row_loc + 1), (@col_loc + 1))
      puts "finished northeastern space"
      northwestern_space = @board.piece_at((@row_loc + 1), (@col_loc - 1))
      puts "finished northwestern space"
    end
    puts "finished white branch"
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
    moves << [@location[0], @location[1]]
    puts "returned moves"
    moves
  end

  def become_queen(row, col, previous_loc)
    @board.space_equals(row, col, Queen.new([row, col], @color) )
    @board.space_equals(previous_loc[0], previous_loc[1], nil) unless [row, col] == @location
    @board.piece_at(row, col).board = @board
  end

  def move_to(row, col)
    move = [row, col]
    current_piece = @board.piece_at(location[0], location[1])
    return nil unless possible_moves.include?(move)
    if row == 7
      become_queen(row, col, @location) 
      return nil
    end
    puts "didn't return nil"
    @has_moved = true unless move == @location
    @board.space_equals(row, col, current_piece)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil) unless move == @location
    current_piece.location = [row, col]
    current_piece.row_loc = row
    current_piece.col_loc = col
    puts "pawn location: #{@location}"
  end
end

# Knight Class inherits Piece Class
class Knight < Piece
  attr_reader :html_text
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @piece = "\u265e"
    @board = nil
    @html_text = "&#9822"
  end

# Knight's movements are different from other pieces
  def possible_moves
    moves = [[-1, 2], [1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1] ]
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
    moves << @location
  end

  def ally_held_position?(move)
    return false if @board.piece_at(move[0], move[1]).nil?
    piece = @board.piece_at(move[0], move[1])
    piece.color == @color
  end

  def apply_relative_pieces(moves)
      moves.delete_if { |move| ally_held_position?(move) }
  end
end

# Bishop Class inherits Piece Class
class Bishop < Piece
  attr_reader :html_text
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 7
    @possible_directions = [:northeast, :northwest,
                            :southeast, :southwest]
    @piece = "\u265d"
    @board = nil
    @html_text = "&#9821"
  end
end

# Rook Class inherits Piece Class
class Rook < Piece
  attr_reader :html_text
  def initialize(location = [0, 0], color = :black)
    @location = location
    @color = color
    @reach = 7
    @possible_directions = [:north, :south, :east, :west]
    @piece = "\u265c"
    @board = nil
    @html_text = "&#9820"
  end
end

# Queen Class inherits Piece Class
class Queen < Piece
  attr_reader :html_text
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
  attr_accessor :row_loc, :col_loc
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
    moves = moves.my_repeated_permutation.to_a
    moves = apply_directions(moves)
    moves = apply_location(moves)
    moves = apply_board_limits(moves)
    moves = apply_relative_pieces(moves)
    #moves.delete_if do |move|
      #checkable_move?(move[0], move[1])
    #end
    moves << @location
  end

  def my_enemies
    me = @board.piece_at(@location[0], @location[1])
    enemies_of(me)
  end

  def check?
    puts "started check"
    @board.compute_moves
    if @color == :black
      puts "started black branch"
      return true if @board.white_moves.include?(@location)
    end
    if @color == :white
      puts "started white branch"
      return true if @board.black_moves.include?(@location)
      puts "returned #{@board.black_moves.include?(@location)}"
    end
    puts "king is not in check"
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
    return nil unless (possible_moves.include?(move)) && (move != @location)
    @board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    @board.space_equals(row, col, current_piece)
    current_piece.location = [row, col]
    current_piece.row_loc = row
    current_piece.col_loc = col
  end

  #def checkable_move?(row, col)
    #@board.compute_moves
    #move = [row, col]
    #if @color == :black
      #return true if @board.white_moves.include?(move)
    #else if @color == :white
      #return true if @board.black_moves.include?(move)
    #end
    #false
  #end
  
  #def checkable_move?(row, col)
    #move = [row, col]
    #previous_loc = @location
    #checkable = false
    #current_piece = @board.piece_at(location[0], location[1])
    #enemy_piece = @board.piece_at(row, col) unless @board.piece_at(row, col).nil?
    #@board.space_equals(row, col, current_piece)
    #@board.space_equals(current_piece.location[0], current_piece.location[1], nil)
    #current_piece.location = [row, col]
    #checkable = current_piece.check?
    #current_piece.location = previous_loc
    #@board.space_equals(current_piece.location[0], current_piece.location[1], current_piece)
    #@board.space_equals(row, col, enemy_piece)
    #checkable
  #end

end




#require 'colored'

class Board
  #attr_reader :board
  attr_accessor :board, :black_moves, :white_moves
  def initialize(board = empty_board)
    @board = board
    set_board
    @black_moves = []
    @white_moves = []
  end

  def compute_moves
    compute_black_moves
    compute_white_moves
  end

  def compute_black_moves
    puts "started computing black moves"
    moves = []
    all_pieces.each do |piece|
      if piece.color == :black 
        piece.possible_moves.each do |move|
          moves << move
        end
      end
    end
    @black_moves = moves
  end

  def compute_white_moves
    puts "started computing white moves"
    moves = []
    all_pieces.each do |piece|
      if piece.color == :white 
        puts "piece is a #{piece.class} at #{piece.location}"
        piece.possible_moves.each do |move|
          puts move.inspect if piece.location == [6, 4]
          moves << move
        end
      end
    end
    puts "finished computing white moves"
    @white_moves = moves
  end

  def stalemate?
    all_pieces.each do |piece|
      return false unless piece.possible_moves.nil?
    end
    true
  end

  def game_over?
    return true if stalemate?
    kings.each do |king|
      return true if king.checkmate?
    end
    false
  end

  def white_king
    kings.each do |king|
      return king if king.color == :white
    end
    nil
  end

  def black_king
    kings.each do |king|
      return king if king.color == :black
    end
    nil
  end

  def kings
    my_kings = []
    all_pieces.each do |piece|
      my_kings << piece if piece.class == King
    end
    my_kings
  end

  def all_pieces
    pieces = []
    0.upto(7).each do |row|
      0.upto(7).each do |col|
        pieces << piece_at(row, col) if ! piece_at(row, col).nil?
      end
    end
    pieces
  end

  def convert_to_move(col, row)
    cols = { a: 0, b: 1, c: 2, d: 3, e: 4, f: 5, g: 6, h: 7 }
    row -= 1
    col = cols[col]

    [row, col]
  end

  def get_piece(col, row)
    cols = { a: 0, b: 1, c: 2, d: 3, e: 4, f: 5, g: 6, h: 7 }
    row -= 1
    col = cols[col]

    piece_at(row, col)
  end

  def set_piece(piece, col, row)
    cols = { a: 0, b: 1, c: 2, d: 3, e: 4, f: 5, g: 6, h: 7 }
    row -= 1
    col = cols[col]

    piece.move_to(row, col)
  end

  def empty_board
    Array.new(8) { Array.new(8) }
  end

  def space_equals(row, col, data)
    @board[row][col] = data
  end

  def occupied_targets
    occupied_targets = []
    0.upto(7).each do |row|
      0.upto(7).each do |column|
        occupied_targets << [row, column] if not @board[row][column].nil?
      end
    end
    occupied_targets
  end

  def piece_at(row, column)
    return nil if (row > 7) || (row < 0) || (column > 7) || (column < 0)
    @board[row][column]
  end

  def set_board
    set_pawns
    set_nobles
  end

  def set_pawns
    @board[1].each_index do |index|
      @board[1][index] = Pawn.new([1, index], :white)
    end
    @board[6].each_index do |index|
      @board[6][index] = Pawn.new([6, index], :black)
    end
  end

  def set_nobles
    set_white_nobles
    set_black_nobles
  end

  def set_white_nobles
    @board[0].each_index do |index|
      case index
      when 0, 7
        @board[0][index] = Rook.new([0, index], :white)
      when 1, 6
        @board[0][index] = Knight.new([0, index], :white)
      when 2, 5
        @board[0][index] = Bishop.new([0, index], :white)
      when 3
        @board[0][3] = Queen.new([0, 3], :white)
      when 4
        @board[0][4] = King.new([0, 4], :white)
      end
    end
  end

  def set_black_nobles
    @board[7].each_index do |index|
      case index
      when 0, 7
        @board[7][index] = Rook.new([7, index], :black)
      when 1, 6
        @board[7][index] = Knight.new([7, index], :black)
      when 2, 5
        @board[7][index] = Bishop.new([7, index], :black)
      when 3
        @board[7][3] = King.new([7, 3], :black)
      when 4
        @board[7][4] = Queen.new([7, 4], :black)
      end
    end
  end
end


class Array
  def my_repeated_permutation
    return_array = []
      self.each do |current_num|
        self.each do |other_num|
          return_array << [current_num, other_num]
        end
      end
    return_array
  end
end