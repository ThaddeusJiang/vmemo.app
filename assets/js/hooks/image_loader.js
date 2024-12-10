export const ImageLoader = {
    mounted() {
        this.el.addEventListener('load', () => {
            this.el.classList.remove('skelton');
            this.el.classList.add('loaded');
        });

        this.el.addEventListener('error', () => {
            this.el.classList.remove('skelton');
            this.el.classList.add('error');
        });
    }
}
