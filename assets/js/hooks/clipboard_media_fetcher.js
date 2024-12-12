
export const ClipboardMediaFetcher = {
    mounted() {
        window.addEventListener('paste', async (event) => {
            const items = event.clipboardData.items;
            if (!items?.length) {
                return;
            }

            const fileInput = this.el.querySelector('input[type="file"]');
            const dataTransfer = new DataTransfer();

            Array.from(fileInput.files).forEach(file => {
                dataTransfer.items.add(file);
            });
            Array.from(items).forEach(item => {
                if (item.kind === 'file' && item.type.startsWith('image')) {
                    const file = item.getAsFile();
                    dataTransfer.items.add(file);
                }
            });

            fileInput.files = dataTransfer.files;
            fileInput.dispatchEvent(new Event('change', { bubbles: true }));
        });
    }
}
