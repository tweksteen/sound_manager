# Sound Manager

Sound manager is a tool to manage any large collection of raw and processed sounds. All the metadata is kept in a single separate file, no modification to the original files is ever performed.

There are two types of sound: Raw or Processed. A Raw sound have the following attributes:

* Name
* Location (where the recording was performed)
* Duration (automatically populated from the file)
* Date and time (when the recording was performed, automatically populated from the filename)
The command to add a raw file to the collection is `add`.

A Processed sound is similar but contains a reference to the original raw sound it was created from. The command to add a processed file to the collection is `link`.

All the sounds are referenced by a unique ID (sha256). Throughout the library, this ID (or a shorted version, as long as no conflict exists) can be used to reference the file.

# Installation

`gem install sound_manager`

By default, the files are expected in `~/sounds`. To change this settings, modify the config.rb file with the correct location.

You will need `audacity` to use the `edit` functionality and `sox` to use `play` and `stats`.

# Usage

```
$ sm add ./raw/160626-155202.WAV "Background Discussion Park" "Glebe, NSW, Australia"
```

```
$ sm ls
147426d  Background Discussion Park        16.07s  2016-06-26 15:52:02
1a79eab  Contact lens solution bottle      14.36s  2015-12-30 16:41:23
```

```
$ sm show 147426d
Name: Background Discussion Park
Hash: 147426df8f17abc2150d266845e17d622564178a83211eb8612b6803d6dd8242
Path: ./raw/160626-155202.WAV
Type: RawSound
Recorded at: 2016-06-26 15:52:02 +1100
Location: Glebe, NSW, Australia
```

```
$ sm play 147426d
```

```
$ sm edit 147426d
```

```
$ sm
usage: sm.rb <add|edit|link|ls|play|rename|search|show|stats|tag>
```




