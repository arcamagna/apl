Usage: tagall.sh [option]

option is either the file format e.g. ogg for batch processing
files of a particular type, or a file name if processing a
single audio file. (Or -h / --help for help.)
When omitted all compatible audio files in the current
directory are processed.

When batch processing all files will have the same album,
artist, date and genre tags. Track and title can be derived
from the file name by entering y when prompted.
(Track only works if the filename starts with a number.)
Alternatively press i to enter track and title information for
each file.

Pressing ENTER whenever prompted will skip ahead retaining
current tag if one exists.

Enter del to delete current tag.
