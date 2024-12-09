export const InfiniteScroll = {
    mounted() {
        const observer = new IntersectionObserver((entries) => {
            if (entries[0].isIntersecting) {
                let page = this.el.dataset.page || 0
                this.pushEvent("load-more", { page: parseInt(page) + 1 })
            }
        })

        observer.observe(this.el)
    },

}
