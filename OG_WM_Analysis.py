import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.io as io
import scipy.stats as stats
import json
from copy import deepcopy
from glm import glm, t_test


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
    df = df[(df.ACC == 1) & (df.probeACC == 1)]
    #print(df)
    #s = pd.Series(df['move_init_msecRT'])
    #print(s)
    #df_num = pd.to_numeric(s, errors='coerce')
    #print(df_num)
    #df[['move_init_msecRT']] = df_num
    #df[('msecRT', 'move_init_msecRT', 'probemsecRT')] = df[('msecRT', 'move_init_msecRT', 'probemsecRT')].astype(str)
    df['move_init_msecRT'] = pd.to_numeric(df['move_init_msecRT'], errors = 'coerce')
    df['msecRT'] = pd.to_numeric(df['msecRT'], errors = 'coerce')
    df['probemsecRT'] = pd.to_numeric(df['probemsecRT'], errors = 'coerce')
    df = df.dropna()
    #print(df)

    #df.select_dtypes(exclude=['object'])
    grouped_TT = df.groupby('TrialType')

    descriptives_TT = grouped_TT[('msecRT', 'move_init_msecRT', 'probemsecRT')]

    neutral = np.array(descriptives_TT.get_group('neutral'), dtype = np.float64)
    compat = np.array(descriptives_TT.get_group('compatible'), dtype = np.float64)
    incompat = np.array(descriptives_TT.get_group('incompatible'), dtype = np.float64)
    means = np.array(descriptives_TT.mean())

    #print(descriptives_TT.size())
    print('\n Descriptive stats for subject ' + str(df.subject.iloc[1]) + ': \n' + str(descriptives_TT.describe()))
    #print(descriptives_TT.mean())


    return neutral, compat, incompat, means

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

    # add some text for labels, title and axes ticks
    ax.set_ylabel('time (msec)', fontsize = 14)
    ax.set_title('RTs by trial conditon', fontsize = 16)
    ax.set_xticks(ind + 1.5*width)
    ax.set_xticklabels(('Total RT', 'Movement initiation', 'Probe RT'), fontsize = 14)

    # Shrink current axis by 20%
    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    ax.legend((rects1[0], rects2[0], rects3[0]), ('Neutral', 'Compatible', 'Incompatible'), loc='center left', bbox_to_anchor=(1, 0.5))

    plt.show()

    return fig

def plot_mean_conditions(subj_means):
    """ Plots the group average means for each condition and measure

    Parameters
    ----------
    subj_means: array shape (conditons, measures, subjects)

    Returns
    -------
    fig: matplotlib figure object for plot

    """
    
    neutral_means = np.mean(subj_means[0,:,:], axis = -1)
    compat_means = np.mean(subj_means[1,:,:], axis = -1)
    incompat_means = np.mean(subj_means[2,:,:], axis = -1)

    neutral_std = np.std(subj_means[0,:,:], axis = -1)
    compat_std = np.std(subj_means[1,:,:], axis = -1)
    incompat_std = np.std(subj_means[2,:,:], axis = -1)

    N = 3 # number of conditions
    ind = np.arange(N)
    width = 0.17 # width of the bars

    fig, ax = plt.subplots()
    error_kw = dict(ecolor='gray', lw=2, capsize=5, capthick=2)
    rects1 = ax.bar(ind, neutral_means, width, color = '#99FFFF', yerr = neutral_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))
    rects2 = ax.bar(ind + width, compat_means, width, color = '#99FF99', yerr = compat_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))
    rects3 = ax.bar(ind + 2*width, incompat_means, width, color = '#FF5C5C', yerr = incompat_std, error_kw = dict(ecolor='black', lw=1.5, capsize=5, capthick=2))

    # add some text for labels, title and axes ticks
    ax.set_ylabel('time (msec)', fontsize = 14)
    ax.set_title('Group average RTs by trial conditon', fontsize = 16)
    ax.set_xticks(ind + 1.5*width)
    ax.set_xticklabels(('Total RT', 'Movement initiation', 'Probe RT'), fontsize = 14)

    # Shrink current axis by 20%
    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    ax.legend((rects1[0], rects2[0], rects3[0]), ('Neutral', 'Compatible', 'Incompatible'), loc='center left', bbox_to_anchor=(1, 0.5))

    plt.show()

    return fig

subjects = np.array([105, 106, 107, 108, 109])
#subjects = np.array([108])
conditions = 3 # conditions (neutral, compatible, incompatible)
measures = 3 # measures (msecRT, move_init_msecRT, probemsecRT)

subj_means = np.zeros((conditions, measures, len(subjects)))

for i in range(len(subjects)):
        neut, comp, incomp, means = read_txt_file('/Users/jcbmiller/Downloads/WM_Simon_dots_mouse_' + str(subjects[i]) + '.txt')

        subj_means[0,:,i] = np.mean(neut, axis = 0)
        subj_means[1,:,i] = np.mean(comp, axis = 0)
        subj_means[2,:,i] = np.mean(incomp, axis = 0)
        #subj_means[...,i] = means

#print(subj_means)

def t_2samp(a, b):
    #res = stats.ttest_ind(a, b) # independent samples t-test
    res = stats.ttest_rel(a, b) # paired t-test
    t = res.statistic
    p = res.pvalue
    return t, p

t,p = t_2samp(subj_means[1,0,:], subj_means[2,0,:])
print('\n Total move RT (compatible versus incompatible): \n t = ',t,'p = ', p)
print('comp. means: ', subj_means[1,0,:], '(msec)', '\nincomp. means: ',subj_means[2,0,:], '(msec)')

t,p = t_2samp(subj_means[1,1,:], subj_means[2,1,:])
print('\n Movement initiation (compatible versus incompatible): \n t = ',t,'p = ', p)
print('comp. means: ', subj_means[1,1,:], '(msec)', '\nincomp. means: ',subj_means[2,1,:], '(msec)')

t,p = t_2samp(subj_means[1,2,:], subj_means[2,2,:])
print('\n Probe RT (compatible versus incompatible): \n t = ',t,'p = ', p)
print('comp. means: ', subj_means[1,2,:], '(msec)', '\nincomp. means: ',subj_means[2,2,:], '(msec)')


#neut,comp,incomp = read_txt_file('/Users/jcbmiller/Downloads/WM_Simon_dots_mouse_105.txt')
#print(neut)
fig = plot_mean_conditions(subj_means)
