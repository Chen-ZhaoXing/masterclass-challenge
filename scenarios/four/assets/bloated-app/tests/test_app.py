import pytest

def test_placeholder():
    """This test file shouldn't be in a production container image."""
    assert True

def test_another_placeholder():
    """More unnecessary files bloating the image."""
    assert 1 + 1 == 2
