###Interactive Chess Game


This is an adaptation of my CLI Chess game that I made in Ruby, [here.](https://github.com/Styx-/chess)

I wanted to figure out a way to bring my game to the browser with Click and Place functionality, but I also wanted to keep all the brains/logic that I'd already figured out in Ruby. This was a somewhat difficult problem since I know very little Javascript. The answer turned out to be a tool called [Opal.](http://opalrb.org/) Among other related things, Opal can compile Ruby Code into the Javascript equivalent, which turned out to be perfect for me.

So after some tweaking of my ruby code, and the addition of some of my own Javascript, Opal brought me home. Feel free to check out the end result at [Rawgit.]

It should be noted that this game does not allow you to play against the computer, it's just the board with piece rules added in, i.e. Queens can go perpendicular and diagonal, and pawns can only go forward.

P.S. I've yet to implement En Passant and Castling. Additionally, the game assumes that you will play in order white, black, white.
