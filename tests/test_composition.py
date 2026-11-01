import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'sources/gar-tools/composition'))
from product import Product
from python_app import environment, package


class CompositionTests(unittest.TestCase):
    def test_board_and_launch_bindings_match_the_existing_hardware_contract(self):
        product = Product(ROOT).validate()
        self.assertEqual('raspberry-pi-5', product.board['id'])
        self.assertEqual('gar-target', product.profile['startup']['manager'])
        binding = json.loads((ROOT / 'hardware/binding.json').read_text(encoding='utf-8'))
        lines = {row['requirement']: row['line'] for row in binding['mappings'] if 'line' in row}
        values = environment(product)
        for key, requirement in {'GAR_ENC_CLK_GPIO': 'encoder-a', 'GAR_ENC_DT_GPIO': 'encoder-b',
                                 'GAR_ENC_SW_GPIO': 'encoder-switch', 'GAR_LCD_DC_GPIO': 'lcd-dc',
                                 'GAR_LCD_RST_GPIO': 'lcd-rst'}.items():
            self.assertEqual(str(lines[requirement]), values[key])
        self.assertEqual('24000000', values['GAR_LCD_SPI_MAX_HZ'])
        self.assertEqual('1000', values['GAR_ENC_DEBOUNCE_US'])
        simulated = environment(product, 'simulation')
        self.assertEqual('0', simulated['GAR_ENC_DEBOUNCE_US'])
        self.assertEqual('video/x-raw,format=YUY2', simulated['GAR_CAMERA_CAPS'])
        self.assertEqual(values['GAR_LCD_SPI_MAX_HZ'], simulated['GAR_LCD_SPI_MAX_HZ'])

    def test_physical_package_preserves_gar_layout_and_actual_application_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary)
            shutil.copyfile(ROOT / 'product.json', copied / 'product.json')
            shutil.copytree(ROOT / 'hardware', copied / 'hardware')
            app_copy = copied / 'sources/gar-stream-tx'
            app_copy.mkdir(parents=True)
            for source in (ROOT / 'sources/gar-stream-tx').glob('*.py'):
                shutil.copyfile(source, app_copy / source.name)
            shutil.copyfile(ROOT / 'sources/gar-stream-tx/requirements.txt', app_copy / 'requirements.txt')
            helper = 'sources/gar-tools/targets/linux-device/runtime/gpio-input/python/gar_gpio_debounce.py'
            (copied / helper).parent.mkdir(parents=True)
            shutil.copyfile(ROOT / helper, copied / helper)
            shutil.copytree(ROOT / 'sources/board-raspberry-pi-5', copied / 'sources/board-raspberry-pi-5',
                            ignore=shutil.ignore_patterns('.git', '__pycache__'))
            output = package(Product(copied), 'artifacts/bundle')
            manifest = json.loads((output / 'artifact.json').read_text(encoding='utf-8'))
            old_contract = json.loads((ROOT / 'config/artifact.json').read_text(encoding='utf-8'))
            self.assertEqual(old_contract['deploy'], manifest['deploy'])
            self.assertEqual(old_contract['target'], manifest['target'])
            app = output / 'files/gar-stream-tx'
            for source in (ROOT / 'sources/gar-stream-tx').glob('*.py'):
                self.assertEqual(source.read_bytes(), (app / source.name).read_bytes())
            self.assertTrue((app / 'gar_gpio_debounce.py').is_file())
            self.assertFalse(any(path.name in ('.env', 'config.json', '__pycache__') for path in output.rglob('*')))
            self.assertFalse(any(path.suffix == '.service' for path in output.rglob('*')))
            self.assertFalse((app / 'panel').exists())


if __name__ == '__main__':
    unittest.main()
