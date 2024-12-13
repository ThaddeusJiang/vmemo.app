export const WindowResizer = {
    mounted() {
        const sendElWidth = () => {
            this.pushEventTo(this.el, "window_resize", {
                width: window.innerWidth,
            })
        }

        sendElWidth()

        window.addEventListener("resize", sendElWidth)
    },
}
