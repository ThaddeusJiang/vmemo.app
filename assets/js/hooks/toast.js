export const Toast = {
    mounted() {
        const id = this.el.id;
        const key = this.el.dataset.key;

        // 5 秒后执行 JS.push 和隐藏操作
        setTimeout(() => {
            // 发送事件到 LiveView
            this.pushEvent("lv:clear-flash", { key: key });

            // 执行隐藏效果
            const element = document.getElementById(id);
            if (element) {
                element.style.transition = "opacity 0.5s ease-out";
                element.style.opacity = "0";

                // setTimeout(() => {
                //     element.remove(); // 完全移除 DOM
                // }, 500); // 等待动画结束
            }
        }, 5000); // 5 秒延迟
    }
}
