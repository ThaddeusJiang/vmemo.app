
export const ClipboardMediaFetcher = {
    async fetchClipboardContent() {
        try {

            if (!navigator.clipboard || !navigator.clipboard.read) {
                console.error("Clipboard API is not supported in this browser.");
                return;
            }

            const clipboardItems = await navigator.clipboard.read();
            const files = []

            clipboardItems.forEach((item, index) => {

                item.types.forEach((type) => {

                    if (type.startsWith('image')) {
                        console.debug("Clipboard item type: ", type);
                        item.getType(type).then((blob) => {
                            const file = new File([blob], 'anyway.png', { type });
                            files.push(file);
                        });
                    }
                });
            });

            return files;
        } catch (error) {
            console.error("Failed to read clipboard content: ", error);
        }
    },

    updateInputFiles(el, files) {
        const dataTransfer = new DataTransfer();

        Array.from(el.files).forEach(file => {
            dataTransfer.items.add(file);
        });

        files.forEach(file => {
            dataTransfer.items.add(file);
        });

        el.files = dataTransfer.files
        el.dispatchEvent(new Event('change', { bubbles: true }));
    },
    mounted() {

        window.addEventListener('paste', async (event) => {
            const files = await this.fetchClipboardContent();

            const fileEl = this.el.querySelector('input[type="file"]');
            this.updateInputFiles(fileEl, files);
        });
    }
}
