# twp-dialog-parser

Hackish implementation of a parser for .yack files, which contain dialog trees
as defined by Ron Gilbert for use in the upcoming [Thimbleweed Park](http://blog.thimbleweedpark.com/)
point-n-click graphic adventure game.

From http://blog.thimbleweedpark.com/drinkingfountain:
"The format for the dialogs is pretty simple. There can be only one 1 and one 2,
etc choice, so the first one chosen is used and the others discarded.
The [random] condition makes the odds of it being chosen random. the -> label
just tells the system where you go if the choice was selected by the player.
You can refer back to http://blog.thimbleweedpark.com/dialog_puzzles
for more examples."

What does .yack stand for? Ron Gilbert explained it's simply a new suffix, so
they can define syntax highlighting for it in text editor.

## Usage

Clone this directory, install the Perl dependencies via CPAN and run:

  yack-parser.pl *.yack

The rest is interactive. Debug mode is currently on. And some .yack syntax
feature are not implemented completely, like the "conditionals".

## See Also

https://github.com/mbensley/thimble-dialog/

http://blog.thimbleweedpark.com/dialog_puzzles

http://blog.thimbleweedpark.com/drinkingfountain

http://blog.thimbleweedpark.com/podcast14

## Copyright

Example .yack-scripts and scripting format, Copyright Ron Gilbert 2015.

Bundled .yack files are presented here for demo purposes only, copyright their
respective authors. Be nice and do not redistribute them without asking, so I
can take this offline here when someone wants me to.