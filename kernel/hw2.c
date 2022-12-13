#include <linux/kernel.h>


asmlinkage long sys_hello(void) 
{
    printk("Hello World!\n");
    return 0;
}

asmlinkage long  sys_set_weight(int weight) 
{
    //TBA
    return 0;
}

asmlinkage long  sys_get_weight(void) 
{
    //TBA
    return 0;
}

asmlinkage long  sys_get_leaf_children_sum(void) 
{
    //TBA
    return 0;
}

pid_t  get_heaviest_ancestor(void) 
{
    //TBA
    return 0;
}