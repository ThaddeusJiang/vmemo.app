export const Resize = {
    mounted() {
        const sendElWidth = () => {
            this.pushEvent("window_resize", {
                width: window.innerWidth,
            })
        }

        sendElWidth()

        window.addEventListener("resize", sendElWidth)
    },
}
