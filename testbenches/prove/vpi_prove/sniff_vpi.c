#include <stdio.h>
#include <stdio.h>
#include "vpi_user.h"

void vpi_proc(void) 
{
   vpiHandle top_iter;
   vpiHandle module_h;
   vpiHandle net_iter;
   vpiHandle h;

   /* get TOP Module handle */
   top_iter = vpi_iterate (vpiModule, NULL);
   module_h = vpi_scan (top_iter);
   if (module_h == NULL) {
      printf("vpiModule no more nets\n");
      return;
   }

   const char *mod_name;
   vpiHandle scope_h;

   mod_name = vpi_get_str (vpiFullName, module_h);
   printf ("TOP Module Name = %s\n", mod_name);
   scope_h = vpi_handle (vpiScope, module_h);
   if (scope_h == NULL) {
      printf("SCOPE_H = NULL\n");
      return;
   }

   s_vpi_value val;
   val.format = vpiBinStrVal;


   // extern vpiHandle  vpi_handle_by_name(char*name, vpiHandle scope);
   vpiHandle hand = vpi_handle_by_name("y1", scope_h);

   /* Get signal value: this works!  */
   vpi_get_value(module_h, &val);
   printf ("Net Name = %s; Value = %s\n",
	 mod_name, val.value.str);

}

void my_handle_register()
{
  s_cb_data cb;

  cb.reason = cbEndOfCompile;
  cb.cb_rtn = &vpi_proc;
  cb.user_data = NULL;
  if (vpi_register_cb (&cb) == NULL)
    vpi_printf ("cannot register EndOfCompile call back\n");
}

void (*vlog_startup_routines[]) () =
{
  my_handle_register,
  0
};
