```

   ██████╗ ██╗   ██╗███╗   ██╗██╗██╗  ██╗
  ██╔════╝ ██║   ██║████╗  ██║██║╚██╗██╔╝
  ██║  ███╗██║   ██║██╔██╗ ██║██║ ╚███╔╝
  ██║   ██║██║   ██║██║╚██╗██║██║ ██╔██╗
  ╚██████╔╝╚██████╔╝██║ ╚████║██║██╔╝ ██╗
   ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝

       ｦ ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ

```

> *"Unfortunately, no one can be told what the Matrix is. You have to see it for yourself."*
> — Morpheus

---

## The Simulation

A shell script that turns your terminal into the Matrix — cascading green character rain with glowing white heads and fading trails. Feed it your repository's source code, and watch your own creation dissolve into the digital rain.

Zero dependencies. Pure shell. No escape.

![gunix demo](images/demo.gif)

---

## Enter the Matrix

**One command. No turning back.**

```sh
git clone https://github.com/gunish/gunix.git && cd gunix && chmod +x matrix.sh
```

Or, if you prefer to live on the edge:

```sh
curl -sL https://raw.githubusercontent.com/gunish/gunix/main/matrix.sh -o matrix.sh && chmod +x matrix.sh
```

Optionally, make it available everywhere:

```sh
ln -s "$(pwd)/matrix.sh" /usr/local/bin/gunix
```

---

## Choose Your Path

> *"This is your last chance. After this, there is no turning back."*

### The Blue Pill — Random Characters

You stay in Wonderland. Katakana, symbols, digits cascade in familiar green rain. Beautiful, but generic.

```sh
./matrix.sh
```

### The Red Pill — Your Own Code

You see how deep the rabbit hole goes. Characters ripped from your actual source files rain down — your code, deconstructed, falling through the void.

```sh
./matrix.sh --code .
```

```sh
./matrix.sh --code ~/projects/my-app
```

![code mode demo](images/demo-code.gif)

---

## How Deep Does the Rabbit Hole Go?

- **Trail effect** — bright white heads, fading through green to darkness
- **Variable speed** — each column falls at its own pace
- **Staggered density** — streams appear and vanish organically
- **Terminal-aware** — fills your window, adapts to resizes on the fly
- **Code extraction** — reads your repo via `git ls-files`, falls back to `find`
- **Clean exit** — press any key, terminal restored instantly
- **Zero dependencies** — just bash, tput, and stty

---

## Requirements

> *"All I'm offering is the truth. Nothing more."*

- `bash`
- A terminal
- The willingness to see

---

## License

MIT

---

<p align="center">
  <i>"There is no spoon."</i>
</p>
