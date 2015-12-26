# include "stdio.h"
# include "string.h"

char const mipsfpga_plus_github_location [] = "http://github.com/MIPSfpga/mipsfpga-plus/blob/master";
char const mipsfpga_download_instruction [] = "http://www.silicon-russia.com/2015/12/11/mipsfpga-download-instructions";

const char * module_names [1000];
int          n_module_names;
int          i_module_to_highlight;

const char * current_module_name                 = NULL;
int          current_module_is_already_described = 0;

//----------------------------------------------------------------------------

#define p         printf

#define tr        p ("<tr>\n");
#define td        p ("<td valign=top>\n");
#define _tr       p ("</tr>\n");
#define _td       p ("</td>\n");
#define hbreak    _td td
#define vbreak    _td _tr tr td
#define ellipsis  p (". . . . . . . . . .<br><br>");

//----------------------------------------------------------------------------

void module
(
    const char * file_url      = NULL,
    const char * module_name   = NULL,
    const char * instance_name = NULL,
    const char * description   = NULL,
    int          colspan       = 1
)
{
    int describe_current_module

        =      current_module_name != NULL
          && ! current_module_is_already_described
          &&   strcmp (module_name, current_module_name) == 0;

    if (! describe_current_module)
        description = NULL;

    char buf [BUFSIZ];

    if (file_url != NULL && strstr (file_url, "http") == NULL)
    {
        sprintf (buf, "%s/%s", mipsfpga_plus_github_location, file_url);
        file_url = buf;
    }

    p ("<table width=100%%");

    if (module_name != NULL || instance_name != NULL || description != NULL) p (" border=1");

    p (" cellpadding=10 cellspacing=0 rules=none>\n");

    p ("<tr><td valign=top");

    if (colspan != 1)
        p (" colspan=%d", colspan);

    p (" nowrap=nowrap bkcolor=#%s>",
        describe_current_module ? "ffff3f" : "cfcfcf");

    if (module_name != NULL || instance_name != NULL) p ("<b>");

    if (module_name != NULL)
    {
        if (file_url != NULL) p ("<a href=\"%s\">", file_url);

        p ("%s", module_name);

        if (file_url != NULL) p ("</a>");
    }

    if (module_name != NULL && instance_name != NULL) p (" ");

    if (instance_name != NULL) p ("%s", instance_name);

    if (module_name != NULL || instance_name != NULL) p ("</b>");

    if ((module_name != NULL || instance_name != NULL) && description != NULL) p (" ");

    if (description != NULL) p ("%s", description);

    p ("</td></tr><tr><td>\n");

    if (describe_current_module)
        current_module_is_already_described = 1;

    colspan = 1;
}

//----------------------------------------------------------------------------

#define _module  p ("</td></tr></table>\n");

#define group   module ();
#define _group  _module

//----------------------------------------------------------------------------

void leaf
(
    const char * file_url      = NULL,
    const char * module_name   = NULL,
    const char * instance_name = NULL,
    const char * description   = NULL
)
{
    module
    (
        file_url,
        module_name,
        instance_name,
        description
    );

    _module
}
