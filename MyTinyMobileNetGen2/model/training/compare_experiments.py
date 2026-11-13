#!/usr/bin/env python3
"""Summarize isolated experiments and draw standalone learning curves."""
import argparse
import json
import os
from pathlib import Path
os.environ.setdefault('MPLCONFIGDIR', '/tmp/gen2-matplotlib')
ROOT=Path(__file__).resolve().parents[2]

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    destination=args.output.resolve()
    if not destination.is_relative_to((ROOT/'model/experiments').resolve()):
        p.error('Output must be under model/experiments')
    baseline=json.loads((ROOT/'model/generated/training.json').read_text())
    experiments={name:json.loads((ROOT/f'model/experiments/{path}/result.json').read_text()) for name,path in
                 [('A constant60','constant60_seed2026'),('B cosine60','cosine60_seed2026')]}
    a,b=experiments.values()
    assert a['initial_weights_sha256']==b['initial_weights_sha256']
    assert a['split_sha256']==b['split_sha256']==baseline['split_sha256']
    assert a['shapes']==b['shapes']==baseline['shapes']
    assert a['parameter_count']==b['parameter_count']==baseline['parameter_count']==7322
    assert a['macs_per_image']==b['macs_per_image']==1805952
    for path in ['constant60_seed2026','cosine60_seed2026']:
        assert json.loads((ROOT/f'model/experiments/{path}/baseline_integrity.json').read_text())['unchanged']
    bh=baseline['history']
    best=max(range(30),key=lambda j:(bh['val_accuracy'][j],-bh['val_loss'][j]))
    assert best==29 # Baseline selected/final checkpoint evaluated on test set.
    summary={'baseline':{'epochs':30,'selected_epoch':best+1,'selected_validation_accuracy':bh['val_accuracy'][best],
        'selected_validation_loss':bh['val_loss'][best],'final_validation_accuracy':bh['val_accuracy'][-1],
        'selected_float_test_accuracy':baseline['test_accuracy'],'selected_float_test_loss':baseline['test_loss'],
        'parameter_count':7322,'macs_per_image':1805952,'training_seconds':baseline['training_seconds']}}
    for name,r in experiments.items():
        h=r['history'];i=r['selected_epoch']['epoch']-1
        expected=max(range(60),key=lambda j:(h['val_accuracy'][j],-h['val_loss'][j]))
        assert i==expected
        summary[name]={'epochs':60,'selected_epoch':i+1,'selected_validation_accuracy':h['val_accuracy'][i],
            'selected_validation_loss':h['val_loss'][i],'final_validation_accuracy':h['val_accuracy'][-1],
            'final_validation_loss':h['val_loss'][-1],'final_training_accuracy':h['accuracy'][-1],
            'final_training_loss':h['loss'][-1],'final_accuracy_gap_pp':100*(h['accuracy'][-1]-h['val_accuracy'][-1]),
            'validation_gain_last10_pp':100*(h['val_accuracy'][-1]-h['val_accuracy'][-11]),
            'validation_loss_change_last10':h['val_loss'][-1]-h['val_loss'][-11],
            **{k:r[k] for k in ['selected_float_test_accuracy','selected_float_test_loss',
                               'parameter_count','macs_per_image','training_seconds','first30_exactly_match_baseline']}}
    destination.mkdir(parents=True,exist_ok=False)
    (destination/'comparison.json').write_text(json.dumps(summary,indent=2)+'\n')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(1,2,figsize=(13,4.8),layout='constrained')
    histories={'Baseline30':bh,**{k:v['history'] for k,v in experiments.items()}}
    for color,(name,h) in zip(['black','tab:blue','tab:orange'],histories.items()):
        epochs=list(range(1,len(h['accuracy'])+1))
        for axis,metric,label in [(axes[0],'accuracy','Accuracy (%)'),(axes[1],'loss','Cross-entropy')]:
            scale=100 if metric=='accuracy' else 1
            axis.plot(epochs,[scale*v for v in h[metric]],'--',color=color,alpha=.7,label=name+' train')
            axis.plot(epochs,[scale*v for v in h['val_'+metric]],color=color,label=name+' validation')
            axis.set(xlabel='Epoch',ylabel=label);axis.grid(alpha=.2)
    axes[0].legend(fontsize=8);fig.suptitle('Gen 2A: identical topology, seed, split and batch size')
    for extension in ['png','svg','pdf']:fig.savefig(destination/f'learning_curves.{extension}',dpi=180)
    plt.close(fig)
    print(json.dumps(summary,indent=2))
if __name__=='__main__':main()
