# jterrain

This is a simple Julia program for generating random realistic-ish terrain for computer graphics applications. It is an implementation of the diamond-square algorithm for terrain generation.

The generated terrain is tileable along the x and y axis.

## Usage

```
jterrain [size]
```

Size must be equal to a power of two, plus one (e.g. 5, 33, 1025). The generated terrain will be written to out.obj