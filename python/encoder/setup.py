from setuptools import setup

setup(
    name='encoder',
    version='1.0',
    author='zero-ljz',
    author_email='me@iapp.run',
    description='Your package description',
    py_modules=['encoder'],
    install_requires=[
        'click'
    ],
    entry_points={
        'console_scripts': [
            'encoder=encoder:cli'
        ]
    }
)