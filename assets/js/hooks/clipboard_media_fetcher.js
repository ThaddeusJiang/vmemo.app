
export const ClipboardMediaFetcher = {
    async fetchClipboardContent() {
        try {

            if (!navigator.clipboard || !navigator.clipboard.read) {
                console.error("Clipboard API is not supported in this browser.");
                return;
            }

            const clipboardItems = await navigator.clipboard.read();
            const files = []

            clipboardItems.forEach((item) => {

                item.types.forEach(async (type) => {

                    console.debug("Clipboard item type: ", type);
                    const blob = await item.getType(type);

                    console.debug("Blob: ", blob);
                    const text = await blob.text();
                    console.debug("Text: ", text);

                    // const url = URL.createObjectURL(blob);
                    // console.debug("Blob URL: ", url);
                    // if (type.startsWith('image')) {
                    //     const blob = await item.getType(type)
                    //     const file = new File([blob], 'anyway.png', { type });
                    //     files.push(file);
                    // }
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


            const fileInput = this.el.querySelector('input[type="file"]');
            const dataTransfer = new DataTransfer();

            Array.from(fileInput.files).forEach(file => {
                dataTransfer.items.add(file);
            });

            const items = event.clipboardData.items;
            if (items) {
                for (let i = 0; i < items.length; i++) {
                    const item = items[i];

                    if (item.kind === 'file') {
                        const file = item.getAsFile();
                        dataTransfer.items.add(file);
                    }
                }
            }

            fileInput.files = dataTransfer.files;
            console.debug("File input: ", fileInput.files);
            fileInput.dispatchEvent(new Event('change', { bubbles: true }));

            // this.updateInputFiles(fileEl, files);
        });
    }
}
