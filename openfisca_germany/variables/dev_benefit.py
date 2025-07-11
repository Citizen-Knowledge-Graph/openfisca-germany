from openfisca_core.periods import MONTH
from openfisca_core.variables import Variable
from openfisca_germany.entities import Person

class dev_benefit(Variable):
    value_type = float
    entity = Person
    definition_period = MONTH
    label = "Dev benefit"
    reference = "https://example.org/simple_benefit"

    def formula(person, period, parameters):
        salary = person("salary", period)
        multiplier = parameters(period).benefits.dev_multiplier
        return salary * multiplier
