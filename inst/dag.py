# Helper functions and extensions for Airflow dags
import sys, os
import shutil
import imp
import glob

#sys.path.append(os.path.join(os.path.dirname(__file__)))

def list_dir_mods(dir):
    """Recursively list python modules in a directory"""
    return [x for x in glob.iglob(dir + '/**/*.py', recursive=True)]

def list_dir_dags(dir):
    """Iterate through all Python modules in a directory, finding all airflow.DAG objects, and returning them as a list"""
    from airflow import DAG
    
    dags = []
    mods = list_dir_mods(dir)
    print('hi')

    for mod_name in mods:
        mod = imp.load_source("mod", mod_name)
        mod_dags = [x for x in list(mod.__dict__.values()) if isinstance(x, DAG)]
        dags.extend(mod_dags)
    
    return dags

def get_dag_args(dags, args):
    """Given a list of Airflow dags and a list of argument names, return a dictionary dag_ids and their corresponding args dictionaries. If a particular dag argument is not defined directly or via default args, 'None' is returned."""
    dags_args = {}
    for dag in dags:
        dag_args = {}
        for arg in args:
            dag_args[arg] = getattr(dag, arg, None) or dag.default_args.get(arg)
        dags_args[dag.dag_id] = dag_args
    
    return dags_args
    


