cimport cython
cimport numpy as np
import numpy as np
import cython
from subprocess import Popen, run, PIPE,DEVNULL
import os
from lxml import etree
import regex as re
from exceptdrucker import errwrite

cdef:
    dict regexcachedict = {}
    object df_bounds_split_regex = re.compile(r"(?:(?:\]\[)|(?:,))", flags=re.I).split
    set[str] boolean_fields = {
        "checkable",
        "checked",
        "clickable",
        "enabled",
        "focusable",
        "focused",
        "scrollable",
        "long-clickable",
        "selected",
        "password",
    }
    np.dtype allcategories = np.dtype(
    [
        ("loop_counter", np.uint32),
        ("tag", "U72"),
        ("NAF", "U24"),
        ("index", np.int32),
        ("text", "U512"),
        ("resource-id", "U256"),
        (
            "class",
            "U256",
        ),
        (
            "package",
            "U256",
        ),
        ("content-desc", "U256"),
        ("checkable", np.uint8),
        ("checked", np.uint8),
        ("clickable", np.uint8),
        ("enabled", np.uint8),
        ("focusable", np.uint8),
        ("focused", np.uint8),
        ("scrollable", np.uint8),
        ("long-clickable", np.uint8),
        ("password", np.uint8),
        ("selected", np.uint8),
        ("bounds", "U128"),
        ("aa_center_x", np.int32),
        ("aa_center_y", np.int32),
        ("aa_area", np.int32),
        ("aa_width", np.int32),
        ("aa_height", np.int32),
        ("aa_start_x", np.int32),
        ("aa_start_y", np.int32),
        ("aa_end_x", np.int32),
        ("aa_end_y", np.int32),
        ("aa_w_h_relation", np.double),
        ("aa_is_square", np.uint8),
    ],
    align=False,
)
    dict dummydict = dict(
    (
        ("loop_counter", 0),
        ("tag", ""),
        ("NAF", ""),
        ("index", -1),
        ("text", ""),
        ("resource-id", ""),
        (
            "class",
            "",
        ),
        (
            "package",
            "",
        ),
        ("content-desc", ""),
        ("checkable", 0),
        ("checked", 0),
        ("clickable", 0),
        ("enabled", 0),
        ("focusable", 0),
        ("focused", 0),
        ("scrollable", 0),
        ("long-clickable", 0),
        ("selected", 0),
        ("password", 0),
        ("bounds", ""),
        ("aa_center_x", -1),
        ("aa_center_y", -1),
        ("aa_area", -1),
        ("aa_width", -1),
        ("aa_height", -1),
        ("aa_start_x", -1),
        ("aa_start_y", -1),
        ("aa_end_x", -1),
        ("aa_end_y", -1),
        ("aa_w_h_relation", -1),
        ("aa_is_square", 0),
    )
)
    str ResetAll = "\033[0m"
    str Bold = "\033[1m"
    str Dim = "\033[2m"
    str Underlined = "\033[4m"
    str Blink = "\033[5m"
    str Reverse = "\033[7m"
    str Hidden = "\033[8m"
    str ResetBold = "\033[21m"
    str ResetDim = "\033[22m"
    str ResetUnderlined = "\033[24m"
    str ResetBlink = "\033[25m"
    str ResetReverse = "\033[27m"
    str ResetHidden = "\033[28m"
    str Default = "\033[39m"
    str Black = "\033[30m"
    str Red = "\033[31m"
    str Green = "\033[32m"
    str Yellow = "\033[33m"
    str Blue = "\033[34m"
    str Magenta = "\033[35m"
    str Cyan = "\033[36m"
    str LightGray = "\033[37m"
    str DarkGray = "\033[90m"
    str LightRed = "\033[91m"
    str LightGreen = "\033[92m"
    str LightYellow = "\033[93m"
    str LightBlue = "\033[94m"
    str LightMagenta = "\033[95m"
    str LightCyan = "\033[96m"
    str White = "\033[97m"
    str BackgroundDefault = "\033[49m"
    str BackgroundBlack = "\033[40m"
    str BackgroundRed = "\033[41m"
    str BackgroundGreen = "\033[42m"
    str BackgroundYellow = "\033[43m"
    str BackgroundBlue = "\033[44m"
    str BackgroundMagenta = "\033[45m"
    str BackgroundCyan = "\033[46m"
    str BackgroundLightGray = "\033[47m"
    str BackgroundDarkGray = "\033[100m"
    str BackgroundLightRed = "\033[101m"
    str BackgroundLightGreen = "\033[102m"
    str BackgroundLightYellow = "\033[103m"
    str BackgroundLightBlue = "\033[104m"
    str BackgroundLightMagenta = "\033[105m"
    str BackgroundLightCyan = "\033[106m"
    str BackgroundWhite = "\033[107m"
    list[str] colors2rotate = [
        LightRed,
        LightGreen,
        LightYellow,
        LightBlue,
        LightMagenta,
        LightCyan,
        White,
    ]

cdef tuple[int,int,int,int] get_coords_from_bounds( object x ):
    cdef:
        tuple ia
    try:
        ia = tuple(map(int, df_bounds_split_regex(str(x).strip(r"[] "))))
        if len(ia) == 4:
            return ia
    except Exception:
        pass
    return (0, 0, 0, 0)


def elements_to_structarray(bytes data):
    cdef:
        object tree = etree.fromstring(data)
        dict mydict = {}
        unsigned int loop_counter = 0
        list[tuple] allstructresults = []
        int aa_start_x, aa_start_y, aa_end_x, aa_end_y, aa_center_x, aa_center_y, aa_width, aa_height,aa_area
        double aa_w_h_relation
        bint aa_is_square
    for view in tree.iterdescendants():
        mydict.update(
            **{
                **dummydict,
                **dict(view.items()),
                **{"tag": view.tag, "loop_counter": loop_counter},
            }
        )
        loop_counter += 1
        aa_start_x, aa_start_y, aa_end_x, aa_end_y = regexcachedict.setdefault(
            mydict["bounds"], get_coords_from_bounds(mydict["bounds"])
        )
        aa_center_x = (aa_start_x + aa_end_x) // 2
        aa_center_y = (aa_start_y + aa_end_y) // 2
        aa_width = aa_end_x - aa_start_x
        aa_height = aa_end_y - aa_start_y
        aa_area = aa_width * aa_height
        aa_w_h_relation = aa_width / aa_height
        aa_is_square = 1 if aa_width == aa_height else 0
        mydict.update(
            {
                "aa_center_x": aa_center_x,
                "aa_center_y": aa_center_y,
                "aa_area": aa_area,
                "aa_width": aa_width,
                "aa_height": aa_height,
                "aa_start_x": aa_start_x,
                "aa_start_y": aa_start_y,
                "aa_end_x": aa_end_x,
                "aa_end_y": aa_end_y,
                "aa_w_h_relation": aa_w_h_relation,
                "aa_is_square": aa_is_square,
            }
        )
        for k1, i1 in mydict.items():
            if k1 in boolean_fields:
                if i1 == "true":
                    mydict[k1] = 1
                else:
                    mydict[k1] = 0
            elif k1 == "index":
                mydict[k1] = int(i1)
            else:
                mydict[k1] = i1
        allstructresults.append(tuple(mydict.values()))
        mydict.clear()
    return np.array(allstructresults, dtype=allcategories)


cpdef str pretty_print_struct_array(
    object a, int shorten_text_by=8):
    cdef:
        list[Py_ssize_t] paddings
        Py_ssize_t len_colors2rotate, counter, i0, i1
        object column_names
    if shorten_text_by < 1:
        shorten_text_by = 1
    paddings = [
        (a.dtype[ix].itemsize // 4 // shorten_text_by)
        if a.dtype[ix].char == "U"
        else a.dtype[ix].itemsize * 3
        for ix in range(len(a.dtype))
    ]

    len_colors2rotate = len(colors2rotate)
    column_names = a.dtype.names
    counter = 0
    for i0 in range((len(a))):
        for i1 in range(len(paddings)):
            print(
                colors2rotate[counter % len_colors2rotate]
                + (
                    (
                        str(str(a[i0][column_names[i1]])
                        .replace("\n", "\\n")
                        .replace("\r", "\\r"))[: paddings[i1]]
                    ).ljust(paddings[i1])
                )
                + ResetAll,
                end=" | ",
            )

        print()
        counter += 1
    return ""

def yield_uiautomator_dump(
    object shell_exe,
    str appname,
    int pid=-1,
    int cpu_limit=15,
    bint include_children=True,
    bint lazy=True,
    double dump_timeout=10,
    str nice_level="-20",
    str outfile="/sdcard/window_dump.xml",
    bint use_cpulimit=True,
    bint run_as_shell=True,
    bint debug=True,
    str su_prefix_for_input="su -c '",
    str su_sufix_for_input="'",
    str cpulimit_path='/data/data/com.termux/files/usr/bin/cpulimit',
    str su_prefix_for_cpulimit="su -c '",
    str su_suffix_for_cpulimit="'",

    bint use_adb=True,
):
    cdef:
        str lazystring = " -z " if lazy else " "
        str include_children_string = " -i " if include_children else " "
        bytes outfilebin = outfile.encode()
        str cmd
        bytes bincmd, cmduibin
        str osgetcwd = os.getcwd()
        object environ= os.environ
        object p1=None
        object p2=None
        object p3=None
    if pid <= 0:
        cmd = rf'''{cpulimit_path}{lazystring}{include_children_string}--limit={cpu_limit} --pid="$(pidof {appname})"'''
    else:
        cmd = rf"""{cpulimit_path}{lazystring}{include_children_string}--limit={cpu_limit} --pid={pid}"""
    cmduibin = su_prefix_for_cpulimit.encode() + cmd.encode() + su_suffix_for_cpulimit.encode() + b"\n\n"
    if not use_cpulimit:
        bincmd = ((su_prefix_for_input + (" ".join(["nice", "-n", (nice_level), "uiautomator", "dump"])))+ su_sufix_for_input).encode()
    else:
        bincmd = ((su_prefix_for_input + (" ".join(["nice", "-n", (nice_level), "uiautomator", "dump",";", "pkill", "cpulimit"])))+ su_sufix_for_input).encode()
    try:
        while True:
            if use_cpulimit:
                p1 = Popen(
                    shell_exe,
                    shell=run_as_shell,
                    env=environ,
                    cwd=osgetcwd,
                    stdin=PIPE,
                    stdout=DEVNULL,
                )
                if debug:
                    print(cmduibin)
                p1.stdin.write(cmduibin)
                p1.stdin.flush()
                p1.stdin.close()
            try:
                p2 = run(
                    shell_exe,
                    input=bincmd,
                    shell=run_as_shell,
                    timeout=dump_timeout,
                    capture_output=True,
                    env=environ,
                    cwd=osgetcwd,
                )
                if debug:
                    print(bincmd)
                if debug:
                    print(p2)
                if use_cpulimit:
                    p1.terminate()
                if outfilebin in p2.stdout or outfilebin in p2.stderr:
                    if use_adb:
                        p3 = run(
                        shell_exe,
                        input=f'cat {outfile}\n'.encode(),
                        shell=run_as_shell,
                        timeout=dump_timeout,
                        capture_output=True,
                        env=environ,
                        cwd=osgetcwd,
                    )
                        data=p3.stdout
                    else:
                        try:
                            f = open(outfile, "ab+")
                            f.seek(0, os.SEEK_SET)
                            data = f.read()
                            f.truncate(0)
                        finally:
                            f.close()
                    if data:
                        yield elements_to_structarray(data)
            except Exception:
                if debug:
                    errwrite()
                try:
                    if use_cpulimit:
                        p1.terminate()
                except Exception:
                    if debug:
                        errwrite()

    except KeyboardInterrupt:
        try:
            if use_cpulimit:
                p1.terminate()
        except Exception:
            if debug:
                errwrite()
