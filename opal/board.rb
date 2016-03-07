#require 'colored'

class Board
  #attr_reader :board
  attr_accessor :board
  def initialize(board = empty_board)
    @board = board
    set_board
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
        pieces << @board[row][col] if !@board[row][col].nil?
      end
    end
    pieces
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

  def display_board
    puts '  a  b  c  d  e  f  g  h'
    7.downto(0) do |line|
      print line + 1
      display_even_line(line) if line.even?
      display_odd_line(line) if line.odd?
    end
    puts '  a  b  c  d  e  f  g  h'
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
    @board[row][column]
  end

  def display_even_line(line)
    0.upto(7) do |cell|
      if @board[line][cell].nil?
        print "   ".black_on_blue if cell.even?
        print "   ".black_on_green if cell.odd?
      else
        if @board[line][cell].color == :black
          print " #{@board[line][cell].piece} ".black_on_blue if cell.even?
          print " #{@board[line][cell].piece} ".black_on_green if cell.odd?
         else
          print " #{@board[line][cell].piece} ".white_on_blue if cell.even?
          print " #{@board[line][cell].piece} ".white_on_green if cell.odd?
        end
      end
      if cell == 7
        print line + 1
      end
    end
    print "\n"
  end

  def display_odd_line(line)
    0.upto(7) do |cell|
      if @board[line][cell].nil?
          print "   ".black_on_green if cell.even?
          print "   ".black_on_blue if cell.odd?
      else
        if @board[line][cell].color == :black
          print " #{@board[line][cell].piece} ".black_on_green if cell.even?
          print " #{@board[line][cell].piece} ".black_on_blue if cell.odd?
        else
          print " #{@board[line][cell].piece} ".white_on_green if cell.even?
          print " #{@board[line][cell].piece} ".white_on_blue if cell.odd?
        end
      end
      if cell == 7
        print line + 1
      end
    end
    print "\n"
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