import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.io as io
import json
from copy import deepcopy


def read_txt_file(fname):
    """ Groups the text file OG_WM script output by trial type, drops incorrect
    trials, and prints out descriptive statistics for each group

    Parameters
    ----------
    fname: path to a space-delimited .txt file

    Returns
    -------
    neutral: array size (1 x # of correct neutral trials)
    compat: array size (1 x # of correct compatible trials)
    incompatible: array size (1 x # of correct incompatible trials)
    """
    df = pd.read_csv(fname, header = 0, sep = ' ')
    #df = df[(df.ACC == 1) & (df.probeACC == 1)]
    df = df[(df.ACC == 1)]
    grouped_TT = df.groupby('TrialType')

    descriptives_TT = grouped_TT[('msecRT', 'enter_box_msecRT', 'move_init_msecRT')]
    #descriptives_TT = grouped_TT[('msecRT')]
    neutral = np.array(descriptives_TT.get_group('neutral'), dtype = float)
    compat = np.array(descriptives_TT.get_group('compatible'), dtype = float)
    incompat = np.array(descriptives_TT.get_group('incompatible'), dtype = float)

    print(descriptives_TT.size())
    print(descriptives_TT.describe())

    print(neutral)
    return neutral, compat, incompat

def plot_indv_conditions(cond1, cond2, cond3):

    """msecRT_means = (np.mean(cond1[:,0]),np.mean(cond2[:,0]),np.mean(cond3[:,0]))
    move_init_msecRT_means = (np.mean(cond1[:,1]),np.mean(cond2[:,1]),np.mean(cond3[:,1]))
    probemsecRT_means = (np.mean(cond1[:,2]),np.mean(cond2[:,2]),np.mean(cond3[:,2]))

    msecRT_stds = (np.std(cond1[:,0]),np.std(cond2[:,0]),np.std(cond3[:,0]))
    move_init_msecRT_stds = (np.std(cond1[:,1]),np.std(cond2[:,1]),np.std(cond3[:,1]))
    probe_msecRT_stds = (np.std(cond1[:,2]),np.std(cond2[:,2]),np.std(cond3[:,2]))"""

    neutral_means = np.mean(cond1, axis = 0)
    compat_means = np.mean(cond2, axis = 0)
    incompat_means = np.mean(cond3, axis = 0)

    neutral_std = np.std(cond1, axis = 0)
    compat_std = np.std(cond2, axis = 0)
    incompat_std = np.std(cond3, axis = 0)

    N = 3 # number of conditions
    ind = np.arange(N)
    width = 0.17 # width of the bars

    fig, ax = plt.subplots()
    error_kw = dict(ecolor='gray', lw=2, capsize=5, capthick=2)
    rects1 = ax.bar(ind, neutral_means, width, color = '#99FFFF', yerr = neutral_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))
    rects2 = ax.bar(ind + width, compat_means, width, color = '#99FF99', yerr = compat_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))
    rects3 = ax.bar(ind + 2*width, incompat_means, width, color = '#FF5C5C', yerr = incompat_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))

    # add some text for labels, title and axes 3ticks
    ax.set_ylabel('time (msec)', fontsize = 14)
    ax.set_title('RTs by trial conditon', fontsize = 16)
    ax.set_xticks(ind + 1.5*width)
    ax.set_xticklabels(('Total RT', 'Box entered', 'Movement initiation'), fontsize = 14)

    # Shrink current axis by 20%
    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    ax.legend((rects1[0], rects2[0], rects3[0]), ('Neutral', 'Compatible', 'Incompatible'), loc='center left', bbox_to_anchor=(1, 0.5))

    plt.show()

    return

n,c,i = read_txt_file('/Users/jcbmiller/Downloads/WM_Simon_dots_mouse_v2_204.txt')
plot_indv_conditions(n,c,i)
