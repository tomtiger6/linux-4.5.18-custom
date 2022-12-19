#include <linux/kernel.h>
#include <linux/sched.h>

asmlinkage long sys_hello(void) 
{
    printk("Hello World!\n");
    return 0;
}

asmlinkage long  sys_set_weight(int num) 
{
    printk("set weight\n");
    if (num < 0)
      return -EINVAL;
    current->weight =num;
    return 0;
}

asmlinkage long  sys_get_weight(void) 
{
  printk("get weight\n");
  return current->weight;
}

asmlinkage long  sys_get_leaf_children_sum(void) 
{
  int sum =0;
  struct task_struct *task;        
  printk("1enter sum+task.weight\n");

  if (list_empty(&current->children)) 
      {
          return -ECHILD;
      }
  list_for_each_entry(task, &current->children,sibling) 
  {
    if (list_empty(&task->children))
    {
      printk("sum+task.weight\n");
      sum += task->weight;
    }
    else
    { 
      printk("get_leaf_child\n");
      sum += sys_get_leaf_children_sum();
      printk("leaf_child worked\n");
    }
  }
  return sum;
}

asmlinkage long sys_get_heaviest_ancestor(void)
{
   struct task_struct *prev = current;
   struct task_struct *task = current;
   int ret_pid= current->pid;
   int best_weight=current->weight;
   printk("ENTER heaviest\n");
   do
    {
        if (task->weight > best_weight)
         {
         printk("update heaviest\n");
         ret_pid=task->pid;
         best_weight=task->weight;
         }
        prev=task;
        task=task->parent;
    } while (prev->pid!=0);

   return ret_pid;
}

