# mix run priv/ts/migrations/2024-12-19.ex
# Note: 在 lib/ 中定义的模块可以被 Vmemo 调用，但是在 priv/ 中定义的模块不能被 Vmemo 调用
Vmemo.Ts.change_1()
