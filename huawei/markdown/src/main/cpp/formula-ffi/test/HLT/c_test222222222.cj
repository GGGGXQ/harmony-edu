// 3rd_party_lib:formula/target/release/formula
//3rd_party_lib_ohos:formula\target\aarch64-linux-ohos\release\formula
// sources_file:..\..\lib\liblatex.so
import formula.*
import std.unittest.*
import std.collection.*
import std.fs.*

@Test
public class c_test_test {
    @TestCase
    func c_testr_01(): Unit {
    var latex = LaTeX("res")
    var str = ###"
\begin{align*}
\left(x-1\right)\left(x+3\right) 
\end{align*}
"###
    var r = latex.parse(str, 2000000000, 40.0, 10.0, 0xFF000000)         
    var w = r.getWidth()
    var h = r.getHeight()
    println(w)
    println(h)
    @Assert(r.getTextSize(),40.0)  
    var g2 = Graphic2D(r,COLOR_FORMAT_BGRA_8888)
    println(g2.width)
    println(g2.height)
    r.draw(g2, 0xFFFFFFFF)
    var arr = r.toBitmap(g2)
    var file: File = File("test.bmp", OpenOption.CreateOrTruncate(false))
    file.write(arr)
    file.close()
}
}

