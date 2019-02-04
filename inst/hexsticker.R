library("hexSticker")
sticker(expression(plot(cars, cex=.5, cex.axis=.5, mgp=c(0,.3,0), xlab="", ylab="")),
        package="hexSticker", p_size=8, s_x=1, s_y=.8, s_width=1.2, s_height=1,
        filename="inst/figures/baseplot.png")

imgpath <- "inst/figures/laminar-laminar.png"
sticker(imgpath, package="laminar", s_x=1, s_y=.75,  filename="inst/figures/laminar.png", dpi = 1000)
