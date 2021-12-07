```python
client.task.create(collaboration=2, organizations=[3], image="harbor2.vantage6.ai/algorithms/kaplan-meier:2", description="test", input={'method': 'main', 'master': True, 'kwargs':{"alice":3, "bob": 4, "helper": 5}}, name='kaplan-meier test')
```