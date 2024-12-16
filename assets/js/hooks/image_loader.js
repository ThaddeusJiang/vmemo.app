export const ImageLoader = {
    mounted() {
        this.el.classList.add('blur-sm');

        this.el.addEventListener('load', () => {
            this.el.classList.remove('blur-sm');
        });

        this.el.addEventListener('error', () => {
            this.el.classList.remove('blur-sm');
        });
    }
}
